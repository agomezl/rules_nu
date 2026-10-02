"""The `nu` module extension: fetches Nushell releases and registers toolchains.

Release hashes are not hard-coded. They are read from the `SHA256SUMS` file
published with every Nushell release and persisted as module extension facts
(in `MODULE.bazel.lock`), so later evaluations are offline and reproducible.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_RELEASES = "https://github.com/nushell/nushell/releases"

# (os, arch) -> Rust target triple used in Nushell release asset names.
_TRIPLES = {
    ("linux", "x86_64"): "x86_64-unknown-linux-gnu",
    ("linux", "aarch64"): "aarch64-unknown-linux-gnu",
    ("macos", "x86_64"): "x86_64-apple-darwin",
    ("macos", "aarch64"): "aarch64-apple-darwin",
    ("windows", "x86_64"): "x86_64-pc-windows-msvc",
}

_BUILD = """\
load("@rules_nu//nu/toolchains:defs.bzl", "nushell_toolchain")

exports_files(["{nu}"])

alias(
    name = "nu_cmd",
    actual = "{nu}",
    visibility = ["//visibility:public"],
)

nushell_toolchain(
    name = "toolchain_impl",
    nu = ":nu_cmd",
)
"""

def _canonical_os(os):
    os = os.lower()
    if os.startswith("mac") or os.startswith("darwin"):
        return "macos"
    if os.startswith("windows"):
        return "windows"
    return os

def _canonical_arch(arch):
    arch = arch.lower()
    if arch in ("amd64", "x64"):
        return "x86_64"
    if arch == "arm64":
        return "aarch64"
    return arch

def _resolve(mctx, facts, version, os, arch):
    """Returns (version, platform triple, sha256) for a release.

    `version` may be empty, meaning the latest release. Results are read from
    and recorded in `facts`; the network is only used for entries not in it.
    """
    platform = _TRIPLES.get((os, arch))
    if not platform:
        fail("Unsupported platform: {} on {}".format(arch, os))
    version = version or facts.get("latest")
    if version and version + "/" + platform in facts:
        return version, platform, facts[version + "/" + platform]

    suffix = "-{}.{}".format(platform, "zip" if os == "windows" else "tar.gz")
    mctx.download(
        "{}/{}/SHA256SUMS".format(_RELEASES, "download/" + version if version else "latest/download"),
        "SHA256SUMS",
    )
    for line in mctx.read("SHA256SUMS").splitlines():
        sha256, _, asset = line.partition("  ")
        if asset.startswith("nu-") and asset.endswith(suffix):
            version = asset[len("nu-"):-len(suffix)]
            return version, platform, sha256
    fail("No Nushell {} release asset for {}".format(version or "latest", platform))

def _toolchain_repo(version, platform, sha256):
    """Declares the http_archive for a release and returns its repo name."""
    windows = "windows" in platform
    name = "nu_{}_{}".format(version, platform).replace(".", "_").replace("-", "_")
    http_archive(
        name = name,
        url = "{}/download/{}/nu-{}-{}.{}".format(
            _RELEASES,
            version,
            version,
            platform,
            "zip" if windows else "tar.gz",
        ),
        sha256 = sha256,
        # Windows archives are flat; the others have a top-level directory.
        strip_prefix = "" if windows else "nu-{}-{}".format(version, platform),
        build_file_content = _BUILD.format(nu = "nu.exe" if windows else "nu"),
    )
    return name

def _hub_impl(rctx):
    lines = ['load("@rules_nu//nu/toolchains:defs.bzl", "NUSHELL_TOOLCHAIN_TYPE")', ""]
    for repo, constraints in rctx.attr.toolchain_repos.items():
        lines += [
            "toolchain(",
            '    name = "{}",'.format(repo),
            '    toolchain = "@{}//:toolchain_impl",'.format(repo),
            "    toolchain_type = NUSHELL_TOOLCHAIN_TYPE,",
            "    exec_compatible_with = {},".format(json.encode(constraints)),
            '    visibility = ["//visibility:public"],',
            ")",
            "",
        ]
    rctx.file("BUILD", "\n".join(lines))

_nu_toolchains_hub = repository_rule(
    implementation = _hub_impl,
    attrs = {"toolchain_repos": attr.string_list_dict()},
)

def _nu_impl(mctx):
    known = mctx.facts
    facts = {}
    toolchains = {}  # repo name -> exec_compatible_with
    requests = [
        (tag.version, tag.os, tag.arch)
        for mod in mctx.modules
        for tag in mod.tags.toolchain
    ]
    urls = [tag for mod in mctx.modules for tag in mod.tags.url]

    for tag in urls:
        if tag.name == "nu_toolchains":
            fail("Repository name 'nu_toolchains' is reserved by rules_nu.")
        http_archive(
            name = tag.name,
            url = tag.url,
            sha256 = tag.sha256,
            strip_prefix = tag.strip_prefix,
            build_file_content = _BUILD.format(nu = tag.nu_path),
        )
        toolchains[tag.name] = tag.exec_compatible_with

    # With nothing configured, use the latest release for the host.
    if not requests and not urls:
        requests = [("", "", "")]

    for version, os, arch in requests:
        os = _canonical_os(os or mctx.os.name)
        arch = _canonical_arch(arch or mctx.os.arch)
        resolved, platform, sha256 = _resolve(mctx, known, version, os, arch)
        if not version:
            facts["latest"] = resolved
        facts[resolved + "/" + platform] = sha256
        toolchains[_toolchain_repo(resolved, platform, sha256)] = [
            "@platforms//os:" + os,
            "@platforms//cpu:" + arch,
        ]

    _nu_toolchains_hub(name = "nu_toolchains", toolchain_repos = toolchains)
    return mctx.extension_metadata(facts = facts)

_platform_attrs = {
    "os": attr.string(
        doc = "Target OS as returned by `mctx.os.name` (e.g. 'linux', 'mac os x', 'windows'). Defaults to the host OS.",
    ),
    "arch": attr.string(
        doc = "Target CPU as returned by `mctx.os.arch` (e.g. 'x86_64', 'aarch64'). Defaults to the host architecture.",
    ),
}

_toolchain = tag_class(
    doc = """\
Fetches a Nushell release for one platform. Without any `toolchain` or `url`
tags, the latest release for the host platform is used.
""",
    attrs = dict(_platform_attrs, version = attr.string(
        doc = """\
Nushell version (e.g. '0.114.0'). Defaults to the latest release. The
resolved version and archive hashes are recorded in `MODULE.bazel.lock`.
""",
    )),
)

_url = tag_class(
    doc = "Registers a custom Nushell archive (e.g. a patched build).",
    attrs = {
        "name": attr.string(doc = "Repository name; may not be 'nu_toolchains'.", mandatory = True),
        "url": attr.string(doc = "Download URL of the archive.", mandatory = True),
        "sha256": attr.string(doc = "Expected SHA-256 of the archive."),
        "strip_prefix": attr.string(doc = "Directory prefix to strip from the archive."),
        "nu_path": attr.string(doc = "Path to the nu binary in the archive.", default = "nu"),
        "exec_compatible_with": attr.string_list(
            doc = "Execution platform constraints, e.g. ['@platforms//os:linux', '@platforms//cpu:x86_64'].",
        ),
    },
)

nu = module_extension(
    implementation = _nu_impl,
    tag_classes = {"toolchain": _toolchain, "url": _url},
)
