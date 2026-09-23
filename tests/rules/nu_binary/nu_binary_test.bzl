load("@rules_nu//nu:rules.bzl", "nu_binary", "nu_library")
load("//:utils.bzl", "wrapped_binary_test")

# ── TC-01: Checks a simple hello world binary ─────────────────────────────────

def test_simple_binary():
    nu_binary(
        name = "hello",
        main = "//:srcs/hello.nu",
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
        main = "//:srcs/check_toolchain.nu",
    )

    wrapped_binary_test(
        name = "nu_toolchain_test",
        binary = ":nu_toolchain",
    )

    return "nu_toolchain_test"

# ── TC-03: Modules scripts can be loaded  ─────────────────────────────────────

def test_module_import():
    nu_binary(
        name = "module_import",
        main = "//:srcs/modules.nu",
        deps = ["//:math"],
    )

    wrapped_binary_test(
        name = "module_import_test",
        binary = ":module_import",
    )

    return "module_import_test"

# ── TC-04: Files are available through data ───────────────────────────────────

def test_data():
    nu_binary(
        name = "data",
        main = "//:srcs/data.nu",
        data = ["//:data/data1.txt"],
    )

    wrapped_binary_test(
        name = "data_test",
        binary = ":data",
    )

    return "data_test"

# ── TC-05: Files are available from transitive data ───────────────────────────────────

def test_transitive_data():
    nu_library(
        name = "a_data",
        srcs = ["//:srcs/a.nu"],
        data = ["//:data/data1.txt"],
    )

    nu_binary(
        name = "transitive_data",
        main = "//:srcs/data.nu",
        deps = [":a_data"],
    )

    wrapped_binary_test(
        name = "transitive_data_test",
        binary = ":transitive_data",
    )

    return "transitive_data_test"

# ── TC-06: Files are available through data via runfiles ─────────────────────

def test_runfiles_data():
    nu_binary(
        name = "runfiles_data",
        main = "//:srcs/runfiles.nu",
        data = ["//:data/data1.txt"],
    )

    wrapped_binary_test(
        name = "runfiles_data_test",
        binary = ":runfiles_data",
    )

    return "runfiles_data_test"

# ── TC-07: Compare runfiles resolution against hermetic-launcher ─────────────

def test_runfiles_comparison():
    nu_binary(
        name = "runfiles_comparison",
        main = "//:srcs/runfiles_comparison.nu",
    )

    wrapped_binary_test(
        name = "runfiles_comparison_test",
        binary = ":runfiles_comparison",
        input = "//:data/data1.txt",
    )

    return "runfiles_comparison_test"
