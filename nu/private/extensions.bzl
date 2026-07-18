load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//nu/private/extensions:templates.bzl", "BUILD_FILE_TEMPLATE")
load("//nu/private/extensions:version.bzl", "create_version")

_url = tag_class(attrs = {
    "url": attr.string(),
    "name": attr.string(),
    "sha256": attr.string(),
    "strip_prefix": attr.string(),
    "nu_path": attr.string(default = "nu"),
})

# Version-based tag class (for automatic platform detection)
_version = tag_class(attrs = {
    "version": attr.string(
        doc = "Nushell version (e.g., '0.114.0'). Supported versions are defined in NUSHELL_RELEASES.",
        mandatory = True,
    ),
    "name": attr.string(
        doc = "Name for the toolchain repository (defaults to 'nu')",
        default = "nu",
    ),
})

def _nu_impl(mctx):
    for mod in mctx.modules:
        # Handle version-based tags
        for version_tag in mod.tags.version:
            create_version(
                name = version_tag.name,
                version = version_tag.version,
                os = mctx.os.name,
                arch = mctx.os.arch,
            )

        # Handle legacy URL-based tags
        for url_tag in mod.tags.url:
            http_archive(
                name = url_tag.name,
                url = url_tag.url,
                sha256 = url_tag.sha256,
                strip_prefix = url_tag.strip_prefix,
                build_file_content = (
                    BUILD_FILE_TEMPLATE.format(
                        name = url_tag.name,
                        nu_path = url_tag.nu_path,
                        exec_compatible_with = "[]",
                    )
                ),
            )

nu = module_extension(
    implementation = _nu_impl,
    tag_classes = {
        "version": _version,
        "url": _url,
    },
)
