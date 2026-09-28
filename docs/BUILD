load("@bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@stardoc//stardoc:stardoc.bzl", "stardoc")

_RULES = [
    "nu_binary",
    "nu_genrule",
    "nu_library",
]

[
    stardoc(
        name = rule + "_docs",
        out = rule + ".generated.md",
        input = "//nu:rules.bzl",
        symbol_names = [rule],
        deps = ["//nu:rules"],
    )
    for rule in _RULES
]

# `bazel test //docs/...` diffs the checked-in docs against the generated
# ones; `bazel run //docs:update` refreshes them.
write_source_files(
    name = "update",
    files = {
        rule + ".md": ":" + rule + "_docs"
        for rule in _RULES
    },
)
