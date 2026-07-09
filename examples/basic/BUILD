load("//nu:rules.bzl", "nu_gen")

nu_gen(
    name = "ex1",
    cmd = "echo foo | save ($bazel.outputs | get 0)",
    outputs = ["foo.txt"],
)
