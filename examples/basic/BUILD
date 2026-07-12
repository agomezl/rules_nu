load("//nu:rules.bzl", "nu_genrule", "nu_libary")

nu_libary(
    name = "hello",
    srcs = ["hello.nu"],
)

nu_libary(
    name = "sum",
    srcs = ["sum.nu"],
    deps = [":hello"],
)

nu_genrule(
    name = "ex1",
    cmd = "echo foo | save ($bazel.outputs | get 0)",
    outputs = ["foo.txt"],
)
