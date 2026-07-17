load("//nu:rules.bzl", "nu_genrule", "nu_library")

nu_library(
    name = "hello",
    srcs = ["hello.nu"],
)

nu_library(
    name = "sum",
    srcs = ["sum.nu"],
    deps = [":hello"],
)

nu_genrule(
    name = "ex1",
    cmd = "echo foo | save ($bazel.outputs | get 0)",
    outputs = ["foo.txt"],
)
