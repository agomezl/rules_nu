load(
    "//nu/tests/nu_binary:nu_binary_test.bzl",
    "test_module_import",
    "test_nu_toolchain",
    "test_simple_binary",
)

test_suite(
    name = "nu_binary_tests",
    tests = [
        test_simple_binary(),
        test_nu_toolchain(),
        test_module_import(),
    ],
)
