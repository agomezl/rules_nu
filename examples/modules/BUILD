load("//nu:rules.bzl", "nu_genrule", "nu_library")

nu_library(
    name = "hello",
    srcs = ["hello.nu"],
)

nu_genrule(
    name = "greeting",
    cmd = """
use examples/modules/hello.nu *
hello | save ($bazel.outputs | get 0)
""",
    outputs = ["greeting.txt"],
    modules = [":hello"],
)
