load(
    ":nu_binary_test.bzl",
    "test_data",
    "test_module_import",
    "test_nu_toolchain",
    "test_simple_binary",
    "test_tools",
)

test_suite(
    name = "tests",
    tests = [
        test_simple_binary(),
        test_nu_toolchain(),
        test_module_import(),
        test_data(),
        test_tools(),
    ],
    visibility = ["//visibility:public"],
)
