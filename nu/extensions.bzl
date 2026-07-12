load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

BUILD_FILE_TEMPLATE = """
load(
    "@rules_nu//nu/toolchains:defs.bzl",
    "nushell_toolchain",
    "NUSHELL_TOOLCHAIN_TYPE",
)

exports_files(["{nu_path}"])

alias(
    name = "nu_cmd",
    actual = "{nu_path}",
    visibility = ["//visibility:public"],
)

nushell_toolchain(
    name = "{name}_nushell",
    nu = ":nu_cmd",
)


toolchain(
    name = "{name}_nushell_toolchain",
    toolchain = ":{name}_nushell",
    toolchain_type = NUSHELL_TOOLCHAIN_TYPE,
    visibility = ["//visibility:public"],
)
"""

_url = tag_class(attrs = {
    "url": attr.string(),
    "name": attr.string(),
    "sha256": attr.string(),
    "strip_prefix": attr.string(),
    "nu_path": attr.string(default = "nu"),
})

def _nu_impl(mctx):
    for mod in mctx.modules:
        for url in mod.tags.url:
            http_archive(
                name = url.name,
                url = url.url,
                sha256 = url.sha256,
                strip_prefix = url.strip_prefix,
                build_file_content = (
                    BUILD_FILE_TEMPLATE.format(
                        name = url.name,
                        nu_path = url.nu_path,
                    )
                ),
            )

nu = module_extension(
    implementation = _nu_impl,
    tag_classes = {"url": _url},
)
