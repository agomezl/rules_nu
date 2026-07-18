"""Build-verification targets for the nu_genrule rule.
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("//nu:rules.bzl", "nu_genrule", "nu_library")

_TEST_ATTRS = {
    "tags": ["manual"],
}

# ── TC-01: Single input appears in $bazel.inputs ──────────────────────────────

def test_inputs_single():
    nu_genrule(
        name = "inputs_single",
        cmd = r"""
            if ($bazel.inputs | length) != 1 {
                error make {msg: $'Expected 1 input, got ($bazel.inputs | length)'}
            }
            "ok" | save $bazel.outputs.0
        """,
        inputs = ["fixtures/input.txt"],
        outputs = [":inputs_single.out"],
        **_TEST_ATTRS
    )

    build_test(
        name = "inputs_single_test",
        targets = [":inputs_single"],
        **_TEST_ATTRS
    )
    return "inputs_single_test"

# ── TC-02: Single output appears in $bazel.outputs ────────────────────────────

def test_outputs_single():
    nu_genrule(
        name = "outputs_single",
        cmd = r"""
            if ($bazel.outputs | length) != 1 {
                error make {msg: $'Expected 1 output, got ($bazel.outputs | length)'}
            }
            "ok" | save $bazel.outputs.0
        """,
        outputs = [":outputs_single.out"],
        **_TEST_ATTRS
    )

    build_test(
        name = "outputs_single_test",
        targets = [":outputs_single"],
        **_TEST_ATTRS
    )
    return "outputs_single_test"

# ── TC-03: Multiple inputs all appear in $bazel.inputs ────────────────────────

def test_inputs_multiple():
    nu_genrule(
        name = "inputs_multiple",
        cmd = r"""
            if ($bazel.inputs | length) != 2 {
                error make {msg: $'Expected 2 inputs, got ($bazel.inputs | length)'}
            }
            if not ($bazel.inputs | any {|p| $p | str ends-with "input1.txt"}) {
                error make {msg: "input1.txt not found in $bazel.inputs"}
            }
            if not ($bazel.inputs | any {|p| $p | str ends-with "input2.txt"}) {
                error make {msg: "input2.txt not found in $bazel.inputs"}
            }
            "ok" | save $bazel.outputs.0
        """,
        inputs = [
            "fixtures/input1.txt",
            "fixtures/input2.txt",
        ],
        outputs = [":inputs_multiple.out"],
        **_TEST_ATTRS
    )

    build_test(
        name = "inputs_multiple_test",
        targets = [":inputs_multiple"],
        **_TEST_ATTRS
    )
    return "inputs_multiple_test"

# ── TC-04: Multiple outputs all appear in $bazel.outputs ──────────────────────

def test_outputs_multiple():
    nu_genrule(
        name = "outputs_multiple",
        cmd = r"""
            if ($bazel.outputs | length) != 2 {
                error make {msg: $'Expected 2 outputs, got ($bazel.outputs | length)'}
            }
            "a" | save $bazel.outputs.0
            "b" | save $bazel.outputs.1
        """,
        outputs = [
            ":outputs_multiple_a.out",
            ":outputs_multiple_b.out",
        ],
        **_TEST_ATTRS
    )

    build_test(
        name = "outputs_multiple_test",
        targets = [":outputs_multiple"],
        **_TEST_ATTRS
    )
    return "outputs_multiple_test"

# ── TC-05: Module from nu_library is available to `use` ──────────────────────

def test_modules_available():
    nu_library(
        name = "mod_test",
        srcs = ["modules/math.nu"],
    )
    nu_genrule(
        name = "modules_available",
        cmd = r"""
            use nu/tests/nu_genrule/modules/math.nu add
            if (add 2 3) != 5 {
                error make {msg: "math::add 2 3 did not return 5"}
            }
            "ok" | save $bazel.outputs.0
        """,
        modules = [":mod_test"],
        outputs = [":modules_available.out"],
        **_TEST_ATTRS
    )

    build_test(
        name = "modules_available_test",
        targets = [":mod_test", ":modules_available"],
        **_TEST_ATTRS
    )
    return "modules_available_test"

# ── TC-06: nu binary is from the toolchain ($nu.current-exe) ─────────────────

def test_nu_exe():
    nu_genrule(
        name = "nu_exe",
        cmd = r"""
            if not (($nu.current-exe | str trim) =~ external) {
                error make {msg: "nu binary is not from a toolchain"}
            }
            "ok" | save $bazel.outputs.0""",
        outputs = [":nu_exe.out"],
        **_TEST_ATTRS
    )

    build_test(
        name = "nu_exe_test",
        targets = [":nu_exe"],
        **_TEST_ATTRS
    )
    return "nu_exe_test"
