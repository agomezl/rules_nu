load("//nu/private/extensions:hub_repo.bzl", "nu_toolchains_hub")
load("//nu/private/extensions:url.bzl", "create_url")
load("//nu/private/extensions:version.bzl", "create_version")

def _nu_impl(mctx):
    # Maps repo_name -> exec_compatible_with constraints for the hub.
    hub_toolchains = {}
    seen = {}

    for mod in mctx.modules:
        for tag in mod.tags.url:
            if tag.name == "nu_toolchains":
                fail(
                    "Repository name 'nu_toolchains' is reserved by rules_nu for the " +
                    "auto-generated toolchains hub. Please use a different name in nu.url().",
                )
            repo, constraints = create_url(tag)
            hub_toolchains[repo] = constraints

        for tag in mod.tags.toolchain:
            os = tag.os or mctx.os.name
            arch = tag.arch or mctx.os.arch
            key = (tag.version, os, arch)
            if key not in seen:
                seen[key] = True
                repo, constraints = create_version(
                    version = tag.version,
                    os = os,
                    arch = arch,
                )
                hub_toolchains[repo] = constraints

    nu_toolchains_hub(
        name = "nu_toolchains",
        toolchain_repos = hub_toolchains,
    )

_toolchain = tag_class(attrs = {
    "version": attr.string(
        doc = """
        Nushell version to fetch (e.g. '0.114.0'). Must be present in
        NUSHELL_RELEASES.
        """,
        mandatory = True,
    ),
    "os": attr.string(
        doc = """
        Target OS identifier as returned by `mctx.os.name` (e.g. 'linux', 'mac
        os x', 'windows'). Defaults to the host OS when omitted.
        """,
        default = "",
    ),
    "arch": attr.string(
        doc = """
        Target CPU architecture as returned by `mctx.os.arch` (e.g. 'x86_64',
        'aarch64'). Defaults to the host architecture when omitted.
        """,
        default = "",
    ),
})

_url = tag_class(attrs = {
    "name": attr.string(
        doc = """
        Name for the external repository. Must be unique and may not be
        'nu_toolchains'.
        """,
        mandatory = True,
    ),
    "url": attr.string(
        doc = """
        Download URL for a tar.gz archive containing the nu binary.
        """,
        mandatory = True,
    ),
    "sha256": attr.string(
        doc = """
        Expected SHA-256 digest of the downloaded archive.
        """,
        default = "",
    ),
    "strip_prefix": attr.string(
        doc = """
        Directory prefix to strip from the archive contents.
        """,
        default = "",
    ),
    "nu_path": attr.string(
        doc = """
        Path to the nu binary inside the unpacked archive.
        """,
        default = "nu",
    ),
    "exec_compatible_with": attr.string_list(
        doc = """
        Execution platform constraints for this toolchain, as Bazel label
        strings (e.g. ['@platforms//os:linux', '@platforms//cpu:x86_64']).
        """,
        default = [],
    ),
})

nu = module_extension(
    implementation = _nu_impl,
    tag_classes = {
        "toolchain": _toolchain,
        "url": _url,
    },
)
