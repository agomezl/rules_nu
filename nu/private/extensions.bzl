load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//nu/private/extensions:defs.bzl", "NUSHELL_PLATFORM_ID")
load("//nu/private/extensions:facts.bzl", "update_facts")
load("//nu/private/extensions:hub_repo.bzl", "nu_toolchains_hub")
load("//nu/private/extensions:url.bzl", "assert_name_is_valid", "create_url")
load("//nu/private/extensions:version.bzl", "resolve_version")

def _nu_impl(mctx):
    # Maps repo_name -> exec_compatible_with constraints for the hub.
    hub_toolchains = {}
    seen = {}
    facts = mctx.facts

    for mod in mctx.modules:
        for tag in mod.tags.url:
            assert_name_is_valid(tag.name)
            repo, constraints = create_url(tag)
            hub_toolchains[repo] = constraints

        for tag in mod.tags.latest + mod.tags.toolchain:
            version_number = getattr(tag, "version", None)
            facts |= update_facts(
                mctx,
                version = version_number,
                facts = facts,
            )
            version = resolve_version(
                raw_version = version_number,
                raw_os = tag.os or mctx.os,
                raw_arch = tag.arch or mctx.arch,
                facts = facts,
            )

            if version.key not in seen:
                seen[version.key] = True
                http_archive(
                    name = version.repo_name,
                    url = version.url,
                    sha256 = version.sha256,
                    build_file = version.build_file,
                )

                hub_toolchains[version.repo_name] = version.constraints

    nu_toolchains_hub(
        name = "nu_toolchains",
        toolchain_repos = hub_toolchains,
    )

    return mctx.metadata(
        facts = facts,
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

_latest = tag_class(attrs = {
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

nu = module_extension(
    implementation = _nu_impl,
    tag_classes = {
        "latest": _latest,
        "toolchain": _toolchain,
        "url": _url,
    },
)
