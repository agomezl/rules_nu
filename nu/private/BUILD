load(":nu_library.bzl", "nu_library")

exports_files(
    [
        "config.nu",
        "env.nu",
    ],
    visibility = ["//visibility:public"],
)

exports_files(
    [
        "nu_binary.bzl",
        "nu_genrule.bzl",
        "nu_library.bzl",
        "providers.bzl",
    ],
    visibility = ["//docs:__pkg__"],
)

nu_library(
    name = "target",
    srcs = ["target.nu"],
    visibility = ["//visibility:public"],
)
