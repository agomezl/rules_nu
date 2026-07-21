load("@rules_nu//nu:rules.bzl", "nu_binary")
load("//:utils.bzl", "wrapped_binary_test")

# ── TC-01: Checks a simple hello world binary ─────────────────────────────────

def test_simple_binary():
    nu_binary(
        name = "hello",
        main = "srcs/hello.nu",
    )

    wrapped_binary_test(
        name = "hello_test",
        binary = ":hello",
    )

    return "hello_test"

# ── TC-02: The nu binary comes from a Bazel toolchain  ────────────────────────

def test_nu_toolchain():
    nu_binary(
        name = "nu_toolchain",
        main = "srcs/check_toolchain.nu",
    )

    wrapped_binary_test(
        name = "nu_toolchain_test",
        binary = ":nu_toolchain",
    )

    return "nu_toolchain_test"

# ── TC-03: Modules scripts can be loaded  ───────────────────────

def test_module_import():
    nu_binary(
        name = "module_import",
        main = "srcs/modules.nu",
        deps = ["//:math"],
    )

    wrapped_binary_test(
        name = "module_import_test",
        binary = ":module_import",
    )

    return "module_import_test"
