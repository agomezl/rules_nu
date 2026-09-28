load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files([
    "config.nu",
    "env.nu",
])

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
    visibility = ["//nu:__subpackages__"],
)

bzl_library(
    name = "nu_library",
    srcs = ["nu_library.bzl"],
    visibility = ["//nu:__subpackages__"],
    deps = [":providers"],
)

bzl_library(
    name = "nu_binary",
    srcs = ["nu_binary.bzl"],
    visibility = ["//nu:__subpackages__"],
    deps = [
        ":providers",
        "//nu/toolchains:defs",
        "@hermetic_launcher//launcher:lib_bzl",
    ],
)

bzl_library(
    name = "nu_genrule",
    srcs = ["nu_genrule.bzl"],
    visibility = ["//nu:__subpackages__"],
    deps = [
        ":nu_binary",
        ":nu_library",
        "@hermetic_launcher//launcher:lib_bzl",
    ],
)
