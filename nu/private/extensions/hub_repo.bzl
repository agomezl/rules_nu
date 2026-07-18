"""Repository rule for the auto-generated nu_toolchains hub repository."""

def _nu_toolchains_hub_impl(rctx):
    lines = [
        'load("@rules_nu//nu/toolchains:defs.bzl", "NUSHELL_TOOLCHAIN_TYPE")',
        "",
    ]
    for repo, constraints in rctx.attr.toolchain_repos.items():
        constraints_str = "[" + ", ".join(['"' + c + '"' for c in constraints]) + "]"
        lines += [
            "toolchain(",
            '    name = "{}",'.format(repo),
            '    toolchain = "@{}//:toolchain_impl",'.format(repo),
            "    toolchain_type = NUSHELL_TOOLCHAIN_TYPE,",
            "    exec_compatible_with = {},".format(constraints_str),
            '    visibility = ["//visibility:public"],',
            ")",
            "",
        ]
    rctx.file("BUILD", content = "\n".join(lines))

nu_toolchains_hub = repository_rule(
    implementation = _nu_toolchains_hub_impl,
    attrs = {
        "toolchain_repos": attr.string_list_dict(
            doc = "Map of repo name to exec_compatible_with constraints.",
        ),
    },
)
