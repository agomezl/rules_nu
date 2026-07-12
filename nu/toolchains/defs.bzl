"""Nushell toolchain definitions."""

# Toolchain type identifier
NUSHELL_TOOLCHAIN_TYPE = Label("@rules_nu//nu/toolchains:type")

def _nushell_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            nu = ctx.file.nu,
        ),
    ]

nushell_toolchain = rule(
    implementation = _nushell_toolchain_impl,
    attrs = {
        "nu": attr.label(
            doc = "The nushell (nu) binary",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            mandatory = True,
        ),
    },
)
