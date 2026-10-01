# Label-based access to the `inputs`, `tools` and `data` of a `nu_genrule`,
# similar to `$(location //some:target)` in Bazel's `genrule`.
#
# The generated genrule script stores the label table and the runfiles handle
# in `$env._NU_GENRULE` before running `cmd`:
#
#   targets:  record<string, list<string>>  (runfiles paths)
#   runfiles: record                        (see `runfiles create`)
#
#   use nu/private/target.nu
#   target location "//some:target"
#   target locations "//some:filegroup"

def lookup [label: string]: nothing -> list<string> {
    let state = $env._NU_GENRULE
    let hit = ($state.targets | get -o $label)
    if ($hit | is-empty) {
        let known = ($state.targets | columns | str join "\n")
        error make { msg: $"unknown label '($label)', expected one of: \n ($known)" }
    }
    $hit | each {|path| runfiles rlocation $state.runfiles $path }
}

# Resolved path of the single file that `label` expands to.
export def location [
    label: string # A label listed in `inputs`, `tools` or `data`.
]: nothing -> string {
    let files = (lookup $label)
    if ($files | length) != 1 {
        error make { msg: $"label '($label)' expands to ($files | length) files, expected exactly 1; use `target locations`" }
    }
    $files | first
}

# Resolved paths of all files that `label` expands to.
export def locations [
    label: string # A label listed in `inputs`, `tools` or `data`.
]: nothing -> list<string> {
    lookup $label
}
