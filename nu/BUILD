load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    ["rules.bzl"],
    visibility = ["//docs:__pkg__"],
)

bzl_library(
    name = "rules",
    srcs = ["rules.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//nu/private:nu_binary",
        "//nu/private:nu_genrule",
        "//nu/private:nu_library",
    ],
)
