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
    exec_compatible_with = {exec_compatible_with},
    visibility = ["//visibility:public"],
)
"""
