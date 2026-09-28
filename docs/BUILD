load("@bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@stardoc//stardoc:stardoc.bzl", "stardoc")

bzl_library(
    name = "rules_nu",
    srcs = [
        "//nu:bzl_srcs",
        "//nu/private:bzl_srcs",
        "//nu/toolchains:bzl_srcs",
    ],
    deps = ["@hermetic_launcher//launcher:lib_bzl"],
)

stardoc(
    name = "nu_binary_docs",
    out = "nu_binary.generated.md",
    input = "//nu:rules.bzl",
    symbol_names = ["nu_binary"],
    deps = [":rules_nu"],
)

stardoc(
    name = "nu_genrule_docs",
    out = "nu_genrule.generated.md",
    input = "//nu:rules.bzl",
    symbol_names = ["nu_genrule"],
    deps = [":rules_nu"],
)

stardoc(
    name = "nu_library_docs",
    out = "nu_library.generated.md",
    input = "//nu:rules.bzl",
    symbol_names = ["nu_library"],
    deps = [":rules_nu"],
)

# `bazel test //docs/...` diffs the checked-in docs against the generated
# ones; `bazel run //docs:update` refreshes them.
write_source_files(
    name = "update",
    files = {
        "nu_binary.md": ":nu_binary_docs",
        "nu_genrule.md": ":nu_genrule_docs",
        "nu_library.md": ":nu_library_docs",
    },
)
