# Load the nushell_toolchain rule
load(":defs.bzl", "nushell_toolchain")

# Nushell toolchain type
toolchain_type(
    name = "type",
    visibility = ["//visibility:public"],
)

# Only used to generate the docs in //docs.
filegroup(
    name = "bzl_srcs",
    srcs = glob(["*.bzl"]),
    visibility = ["//docs:__pkg__"],
)
