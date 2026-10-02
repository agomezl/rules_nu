# Template for per-platform repos.
# Only the nushell_toolchain impl lives here; the toolchain() wrapper with
# exec_compatible_with is generated in the hub repo so Bazel can resolve it.
PER_PLATFORM_BUILD_TEMPLATE = """
load("@rules_nu//nu/toolchains:defs.bzl", "nushell_toolchain")

exports_files(["{nu_path}"])

alias(
    name = "nu_cmd",
    actual = "{nu_path}",
    visibility = ["//visibility:public"],
)

nushell_toolchain(
    name = "toolchain_impl",
    nu = ":nu_cmd",
)
"""
