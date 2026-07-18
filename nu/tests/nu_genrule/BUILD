load(
    ":nu_genrule_test.bzl",
    "test_inputs_multiple",
    "test_inputs_single",
    "test_modules_available",
    "test_nu_exe",
    "test_outputs_multiple",
    "test_outputs_single",
)

test_suite(
    name = "nu_genrule_tests",
    tests = [
        test_inputs_single(),
        test_outputs_single(),
        test_inputs_multiple(),
        test_outputs_multiple(),
        test_modules_available(),
        test_nu_exe(),
    ],
)
