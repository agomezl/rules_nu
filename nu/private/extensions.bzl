load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//nu/private/extensions:defs.bzl", "NUSHELL_PLATFORM_ID")
load("//nu/private/extensions:facts.bzl", "create_facts", "update_facts")
load("//nu/private/extensions:hub_repo.bzl", "nu_toolchains_hub")
load(
    "//nu/private/extensions:url.bzl",
    "assert_name_is_available",
    "create_url",
)
load("//nu/private/extensions:version.bzl", "resolve_version")

def _nu_version_tag_impl(mctx, version_tag, facts, hub_toolchains):
    version_number = getattr(version_tag, "version", None)
    update_facts(
        mctx,
        version = version_number,
        facts = facts,
    )
    version = resolve_version(
        raw_version = version_number,
        raw_os = version_tag.os or mctx.os.name,
        raw_arch = version_tag.arch or mctx.os.arch,
        facts = facts,
    )

    if version.repo_name not in hub_toolchains:
        http_archive(
            name = version.repo_name,
            url = version.url,
            sha256 = version.sha256,
            build_file_content = version.build_file,
        )

    if version.constraints != hub_toolchains.get(
        version.repo_name,
        version.constraints,
    ):
        fail("BUG: version constraints mismatch for {}: {} != {}".format(
            version.repo_name,
            version.constraints,
            hub_toolchains[version.repo_name],
        ))

    return version.repo_name, version.constraints

def _nu_url_tag_impl(mctx, url_tag, facts, hub_toolchains):
    assert_name_is_available(url_tag.name, hub_toolchains)
    return create_url(url_tag)

def _nu_impl(mctx):
    # Maps repo_name -> exec_compatible_with constraints for the hub.
    hub_toolchains = {}
    facts = create_facts(mctx)

    for mod in mctx.modules:
        for tag in mod.tags.latest + mod.tags.toolchain:
            repo, constraints = _nu_version_tag_impl(mctx, tag, facts, hub_toolchains)
            hub_toolchains[repo] = constraints

        for tag in mod.tags.url:
            repo, constraints = _nu_url_tag_impl(mctx, tag, facts, hub_toolchains)
            hub_toolchains[repo] = constraints

    nu_toolchains_hub(
        name = "nu_toolchains",
        toolchain_repos = hub_toolchains,
    )

    if hasattr(mctx, "facts"):
        return mctx.extension_metadata(facts = facts.all())
    return mctx.extension_metadata()

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
