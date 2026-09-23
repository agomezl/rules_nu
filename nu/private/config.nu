# A self-contained Nushell implementation of the "Bazel runfiles" discovery
# and resolution interface that is implemented, with small variations, by
# every per-language Bazel runfiles library (@rules_python//python/runfiles,
# @rules_go//go/runfiles, @rules_rust//tools/runfiles, etc).
#
# Background reading:
# - https://fuchsia.googlesource.com/fuchsia/+/HEAD/build/bazel/BAZEL_RUNFILES.md
#   describes the on-disk layout Bazel produces (runfiles directories,
#   `.runfiles_manifest` files, and `_repo_mapping`/`.repo_mapping` files) and
#   the algorithm every runfiles library is expected to follow.
# - https://github.com/hermeticbuild/hermetic-launcher/blob/main/runfiles-stub/src/runfiles.rs
#   is a from-scratch (no_std) Rust implementation of the discovery/lookup
#   logic used as the structural reference for this file (source selection
#   order, manifest parsing/escaping rules, and prefix lookups for
#   TreeArtifacts).
#
# This file intentionally has no dependency on anything else in rules_nu: it
# can be copied and `use`d standalone in any Nushell script that needs to
# locate its Bazel-provided data dependencies at runtime.
#
# Typical usage from a `nu_binary`/`nu_test` entry point:
#
#   use runfiles.nu
#
#   let rf = (runfiles create)
#   if $rf == null {
#       error make { msg: "could not locate runfiles" }
#   }
#   let data_path = (runfiles rlocation $rf "my_project/data/file")
#
# ---------------------------------------------------------------------------
# Internal helpers (not exported)
# ---------------------------------------------------------------------------

# Whether `path` is an absolute filesystem path. Handles both POSIX
# (`/foo/bar`) and Windows (`C:\foo`, `C:/foo`, `\\server\share`) conventions,
# since a Nushell script using this library may run on either platform.
def is-absolute-path [path: string]: nothing -> bool {
    if ($path | str starts-with '/') {
        true
    } else if ($path | str starts-with '\') {
        true
    } else if ($path =~ '^[A-Za-z]:[\\/]') {
        true
    } else {
        false
    }
}

# `true` if `path` exists and is a directory. Plain `path exists` alone
# doesn't distinguish files from directories.
def dir-exists [path: string]: nothing -> bool {
    ($path | path exists) and (($path | path type) == "dir")
}

# Whether directory-based runfiles should be preferred over manifest-based
# ones when both an environment variable and/or a sibling path could apply.
#
# Bazel only materializes a real `<binary>.runfiles/` symlink tree on
# platforms that support symlinks; on Windows it emits only a manifest file
# (see the "RUNFILES DIRECTORY LAYOUT" section of the Fuchsia doc above), so a
# sibling `.runfiles` directory found there would be stale or incomplete and
# the manifest must win instead.
def prefer-directory-source []: nothing -> bool {
    $nu.os-info.family != "windows"
}

# Converts the forward-slash-separated `path` (the form used inside manifests
# and by `rlocation` callers) into the current platform's native separator,
# for use when joining onto a directory-based runfiles root.
def to-native-path [path: string]: nothing -> string {
    $path | str replace --all '/' (char path_sep)
}

def join-runfiles-path [dir: string, path: string]: nothing -> string {
    $dir | path join (to-native-path $path)
}

# ---- Manifest parsing -------------------------------------------------

# Reverses the escaping Bazel applies to a manifest field (source or target)
# whenever a line can't be written in the plain `<source> <target>` form,
# i.e. whenever either field contains a space, newline or backslash. Escaped
# lines start with a leading space, and use `\s`, `\n`, `\b` for space,
# newline and backslash respectively. Order matters: `\b` must be unescaped
# last so that a literal backslash it produces is never mistaken for the
# start of another escape sequence.
def unescape-manifest-field [field: string]: nothing -> string {
    $field
    | str replace --all '\s' ' '
    | str replace --all '\n' "\n"
    | str replace --all '\b' '\'
}

# Parses a single manifest line into a `{source, target}` record, or `null`
# if the line should be skipped (e.g. the workspace marker line, which has no
# space and is not a real runfiles entry).
def parse-manifest-line [line: string]: nothing -> any {
    if ($line | str starts-with ' ') {
        let parts = ($line | str substring 1.. | split row -n 2 ' ')
        if ($parts | length) < 2 {
            return null
        }
        {
            source: (unescape-manifest-field ($parts | get 0))
            target: (unescape-manifest-field ($parts | get 1))
        }
    } else {
        let parts = ($line | split row -n 2 ' ')
        if ($parts | length) < 2 {
            return null
        }
        let source = ($parts | get 0)
        let target = ($parts | get 1)
        # A source with no target maps to itself (this can happen for
        # root symlinks that point at themselves).
        { source: $source, target: (if ($target | is-empty) { $source } else { $target }) }
    }
}

# Loads and parses a `MANIFEST` / `*.runfiles_manifest` file into a
# `table<source: string, target: string>`. Returns `null` if the file
# doesn't exist or can't be read.
def load-manifest [path: string]: nothing -> any {
    let content = (try { open --raw $path } catch { null })
    if $content == null {
        return null
    }
    $content
    | lines
    | each {|line| parse-manifest-line $line }
    | where {|row| $row != null }
}

# Resolves `key` (a runfiles-root-relative path, e.g. `_main/data/file`)
# against a parsed manifest. Falls back to a prefix match for paths that live
# inside a directory which is itself the manifest entry (this happens for
# Bazel TreeArtifacts, where only the directory -- not each file inside it --
# is listed).
def manifest-lookup [manifest: table, key: string]: nothing -> any {
    let hit = ($manifest | where source == $key)
    if ($hit | is-not-empty) {
        return (($hit | first).target)
    }

    mut best_target = null
    mut best_len = 0
    for row in $manifest {
        let prefix = $"($row.source)/"
        if ($key | str starts-with $prefix) and (($row.source | str length) > $best_len) {
            $best_len = ($row.source | str length)
            $best_target = ($row.target + ($key | str substring $best_len..))
        }
    }
    $best_target
}

# ---- Repository mapping parsing ---------------------------------------
#
# See the "REPOSITORY MAPPING FILES" section of the Fuchsia doc: this table
# translates `(source_repo, apparent_name)` pairs to the `canonical_name`
# that is actually used as the top-level directory name inside the runfiles
# tree/manifest. `source_repo` is `""` for the main repository/workspace.

def parse-repo-mapping-line [line: string]: nothing -> any {
    if ($line | is-empty) {
        return null
    }
    let parts = ($line | split row ',')
    if ($parts | length) != 3 {
        return null
    }
    {
        source_repo: ($parts | get 0)
        apparent: ($parts | get 1)
        canonical: ($parts | get 2)
    }
}

# Loads a `_repo_mapping`/`*.repo_mapping` file, if `path` is non-null and
# exists. Always returns a table (empty when there is nothing to load), since
# an absent/empty repo mapping simply means apparent and canonical repository
# names are identical (e.g. Bzlmod is not in use).
def load-repo-mapping [path: any]: nothing -> table {
    if $path == null {
        return []
    }
    let content = (try { open --raw $path } catch { null })
    if $content == null {
        return []
    }
    $content
    | lines
    | each {|line| parse-repo-mapping-line $line }
    | where {|row| $row != null }
}

def repo-mapping-lookup [mapping: table, source_repo: string, apparent: string]: nothing -> any {
    let hit = ($mapping | where source_repo == $source_repo and apparent == $apparent)
    if ($hit | is-empty) {
        null
    } else {
        ($hit | first).canonical
    }
}

# Finds the path to the repo mapping file associated with a manifest-based
# `runfiles` record: either the path recorded under the well-known
# `_repo_mapping` manifest key, or (falling back, for manifests that don't
# list it) the Bazel-standard `<binary>.repo_mapping` file that sits next to
# a `<binary>.runfiles_manifest`.
def find-repo-mapping-path [manifest_path: string, manifest: table]: nothing -> any {
    let from_manifest = (manifest-lookup $manifest "_repo_mapping")
    if $from_manifest != null {
        return $from_manifest
    }
    if ($manifest_path | str ends-with ".runfiles_manifest") {
        let candidate = ($manifest_path | str replace -r '\.runfiles_manifest$' '.repo_mapping')
        if ($candidate | path exists) {
            return $candidate
        }
    }
    null
}

# Derives the runfiles directory a manifest path would sit inside, used only
# to populate `RUNFILES_DIR` for child processes (see `runfiles env-vars`).
# This does not imply that directory actually exists on disk.
def manifest-runfiles-dir [manifest_path: string]: nothing -> string {
    if ($manifest_path | str ends-with ".runfiles_manifest") {
        $manifest_path | str replace -r '_manifest$' ''
    } else if ($manifest_path | str ends-with "/MANIFEST") or ($manifest_path | str ends-with '\MANIFEST') {
        $manifest_path | str replace -r '[/\\]MANIFEST$' ''
    } else {
        ""
    }
}

# ---- Source construction -----------------------------------------------

def make-directory-runfiles [dir: string]: nothing -> record {
    let mapping_path = ($dir | path join "_repo_mapping")
    {
        kind: "directory"
        path: $dir
        manifest: []
        repo_mapping: (load-repo-mapping (if ($mapping_path | path exists) { $mapping_path } else { null }))
    }
}

def make-manifest-runfiles [manifest_path: string]: nothing -> any {
    let manifest = (load-manifest $manifest_path)
    if $manifest == null {
        return null
    }
    {
        kind: "manifest"
        path: $manifest_path
        manifest: $manifest
        repo_mapping: (load-repo-mapping (find-repo-mapping-path $manifest_path $manifest))
    }
}

# Tries `RUNFILES_DIR`/`RUNFILES_MANIFEST_FILE` from the environment, in the
# platform's preferred order. Returns `null` if neither is usable.
def from-environment []: nothing -> any {
    let runfiles_dir = ($env.RUNFILES_DIR? | default "")
    let manifest_file = ($env.RUNFILES_MANIFEST_FILE? | default "")

    let try_dir = {||
        if ($runfiles_dir | is-not-empty) and (dir-exists $runfiles_dir) {
            make-directory-runfiles $runfiles_dir
        } else {
            null
        }
    }
    let try_manifest = {||
        if ($manifest_file | is-not-empty) and ($manifest_file | path exists) {
            make-manifest-runfiles $manifest_file
        } else {
            null
        }
    }

    if (prefer-directory-source) {
        let result = (do $try_dir)
        if $result != null { $result } else { (do $try_manifest) }
    } else {
        let result = (do $try_manifest)
        if $result != null { $result } else { (do $try_dir) }
    }
}

# Probes for a `<executable>.runfiles` directory and/or a
# `<executable>.runfiles_manifest` file next to `exe`, in the platform's
# preferred order. Returns `null` if neither is found.
def from-sibling-paths [exe: string]: nothing -> any {
    let dir = $"($exe).runfiles"
    let manifest_file = $"($exe).runfiles_manifest"

    let try_dir = {|| if (dir-exists $dir) { make-directory-runfiles $dir } else { null } }
    let try_manifest = {|| if ($manifest_file | path exists) { make-manifest-runfiles $manifest_file } else { null } }

    if (prefer-directory-source) {
        let result = (do $try_dir)
        if $result != null { $result } else { (do $try_manifest) }
    } else {
        let result = (do $try_manifest)
        if $result != null { $result } else { (do $try_dir) }
    }
}

# Translates the leading `apparent_name` path segment of `path` through
# `mapping`, for the given `source_repo`. Returns `path` unchanged when there
# is no applicable mapping entry (including when `mapping` is empty, e.g.
# Bzlmod is disabled), since apparent and canonical names are then the same.
def resolve-repo-mapping [mapping: table, source_repo: string, path: string]: nothing -> string {
    if ($mapping | is-empty) {
        return $path
    }
    let parts = ($path | split row -n 2 '/')
    if ($parts | length) < 2 {
        return $path
    }
    let apparent = ($parts | get 0)
    let remainder = ($parts | get 1)
    let canonical = (repo-mapping-lookup $mapping $source_repo $apparent)
    if $canonical == null {
        $path
    } else {
        $"($canonical)/($remainder)"
    }
}

# ---------------------------------------------------------------------------
# Public interface
# ---------------------------------------------------------------------------

# Discovers this process's runfiles, the same way every Bazel runfiles
# library does:
#
#   1. `RUNFILES_DIR`, if set and pointing at an existing directory.
#   2. `RUNFILES_MANIFEST_FILE`, if set and pointing at an existing file.
#   3. A `<executable>.runfiles` directory or `<executable>.runfiles_manifest`
#      file sitting next to the running executable/script.
#
# `--executable` overrides the "running executable" path used by step 3; it
# defaults to `$env.CURRENT_FILE`, i.e. the top-level script Nushell was
# invoked with.
#
# Returns a runfiles source record (an opaque value that should be passed to
# the other `runfiles` commands in this module), or `null` if runfiles could
# not be located at all.
export def "runfiles create" [
    --executable: string # Path used to probe for sibling `.runfiles`/`.runfiles_manifest` entries.
]: nothing -> any {
    let from_env = (from-environment)
    if $from_env != null {
        return $from_env
    }

    let exe = ($executable | default ($env.CURRENT_FILE? | default ""))
    if ($exe | is-empty) {
        return null
    }
    from-sibling-paths $exe
}

# Resolves a runfiles-root-relative `path` (e.g. `my_project/data/file`, where
# `my_project` is a repository's apparent or canonical name) to the file's
# real, absolute, on-disk location.
#
# `path` may not exist even when a value is returned: like every other
# runfiles library, callers should check for existence themselves before
# depending on the result.
#
# `--source-repo` is the canonical name of the repository whose repo mapping
# should be used to translate `path`'s leading apparent-repository-name
# segment into a canonical one; it defaults to `""`, the main
# repository/workspace, which is almost always what a top-level `nu_binary`
# or `nu_test` entry point wants. Pass a different canonical name (as found
# in a `_repo_mapping` file) when resolving a path on behalf of code that
# lives in a different repository.
#
# Returns `null` if `path` is not known to be a runfile.
export def "runfiles rlocation" [
    runfiles: record # A value previously returned by `runfiles create`.
    path: string # Runfiles-root-relative path to resolve.
    --source-repo: string = "" # Canonical name of the repository `path` should be resolved from.
]: nothing -> any {
    if ($path | is-empty) {
        return null
    }

    # Absolute paths are already resolved; every runfiles library hands them
    # back untouched instead of trying to look them up.
    if (is-absolute-path $path) {
        return $path
    }

    let resolved_path = (resolve-repo-mapping $runfiles.repo_mapping $source_repo $path)

    if $runfiles.kind == "directory" {
        join-runfiles-path $runfiles.path $resolved_path
    } else {
        manifest-lookup $runfiles.manifest $resolved_path
    }
}

# Returns the environment variables a subprocess should be started with so
# that, if it is itself a Bazel-built binary using a runfiles library, it can
# find the same runfiles tree/manifest as this process.
export def "runfiles env-vars" [
    runfiles: record # A value previously returned by `runfiles create`.
]: nothing -> record {
    if $runfiles.kind == "directory" {
        { RUNFILES_DIR: $runfiles.path }
    } else {
        {
            RUNFILES_MANIFEST_FILE: $runfiles.path
            RUNFILES_DIR: (manifest-runfiles-dir $runfiles.path)
        }
    }
}

# Returns the manifest file path for a manifest-based `runfiles` value, or
# `null` if it is directory-based.
export def "runfiles manifest-path" [
    runfiles: record # A value previously returned by `runfiles create`.
]: nothing -> any {
    if $runfiles.kind == "manifest" { $runfiles.path } else { null }
}

# Returns the runfiles root directory for a directory-based `runfiles`
# value, or `null` if it is manifest-based.
export def "runfiles dir-path" [
    runfiles: record # A value previously returned by `runfiles create`.
]: nothing -> any {
    if $runfiles.kind == "directory" { $runfiles.path } else { null }
}
