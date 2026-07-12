load("//nu:rules.bzl", "nu_genrule")

nu_genrule(
    name = "ex1",
    cmd = "echo foo | save ($bazel.outputs | get 0)",
    outputs = ["foo.txt"],
)
