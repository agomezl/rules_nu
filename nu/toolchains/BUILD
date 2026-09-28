load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

# Load the nushell_toolchain rule
load(":defs.bzl", "nushell_toolchain")

# Nushell toolchain type
toolchain_type(
    name = "type",
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "defs",
    srcs = ["defs.bzl"],
    visibility = ["//nu:__subpackages__"],
)
