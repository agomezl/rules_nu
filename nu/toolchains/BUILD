# Load the nushell_toolchain rule
load(":defs.bzl", "nushell_toolchain")

exports_files(
    ["defs.bzl"],
    visibility = ["//docs:__pkg__"],
)

# Nushell toolchain type
toolchain_type(
    name = "type",
    visibility = ["//visibility:public"],
)
