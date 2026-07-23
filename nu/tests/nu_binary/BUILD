load(
    ":nu_binary_test.bzl",
    "test_module_import",
    "test_nu_toolchain",
    "test_simple_binary",
)

test_suite(
    name = "tests",
    tests = [
        test_simple_binary(),
        test_nu_toolchain(),
        # TODO: Module path resolution currently doesn't work for external targets
        test_module_import(),
    ],
    visibility = ["//visibility:public"],
)
