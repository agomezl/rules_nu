"""Build-verification targets for the nu_genrule rule.
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_nu//nu:rules.bzl", "nu_binary", "nu_genrule", "nu_library")

# ── TC-01: Single input is found via `target location` ────────────────────────

def test_inputs_single():
    nu_genrule(
        name = "inputs_single",
        cmd = r"""
            if (open (target location "//:fixtures/input.txt") | str trim) != "input content" {
                error make {msg: "unexpected input.txt content"}
            }
            "ok" | save $bazel.outputs.0
        """,
        inputs = ["//:fixtures/input.txt"],
        outputs = [":inputs_single.out"],
    )

    build_test(
        name = "inputs_single_test",
        targets = [":inputs_single"],
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
    )

    build_test(
        name = "outputs_single_test",
        targets = [":outputs_single"],
    )
    return "outputs_single_test"

# ── TC-03: Multiple inputs are each found via `target location` ───────────────

def test_inputs_multiple():
    nu_genrule(
        name = "inputs_multiple",
        cmd = r"""
            if not ((target location "//:fixtures/input1.txt") | str ends-with "input1.txt") {
                error make {msg: "input1.txt not found"}
            }
            if not ((target location "//:fixtures/input2.txt") | str ends-with "input2.txt") {
                error make {msg: "input2.txt not found"}
            }
            "ok" | save $bazel.outputs.0
        """,
        inputs = [
            "//:fixtures/input1.txt",
            "//:fixtures/input2.txt",
        ],
        outputs = [":inputs_multiple.out"],
    )

    build_test(
        name = "inputs_multiple_test",
        targets = [":inputs_multiple"],
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
    )

    build_test(
        name = "outputs_multiple_test",
        targets = [":outputs_multiple"],
    )
    return "outputs_multiple_test"

# ── TC-05: Module from nu_library is available to `use` ──────────────────────

def test_modules_available():
    nu_genrule(
        name = "modules_available",
        cmd = r"""
            use modules/math.nu add
            if (add 2 3) != 5 {
                error make {msg: "math::add 2 3 did not return 5"}
            }
            "ok" | save $bazel.outputs.0
        """,
        deps = ["//:math"],
        outputs = [":modules_available.out"],
    )

    build_test(
        name = "modules_available_test",
        targets = [":modules_available"],
    )
    return "modules_available_test"

# ── TC-06: nu binary is from the toolchain ($nu.current-exe) ─────────────────

def test_nu_exe():
    nu_genrule(
        name = "nu_exe",
        cmd = r"""
            let nu_exe: string = ($nu.current-exe | str trim)
            let heuristic_paths: list<string> = ["/_main/", "/external/", '/\+nu\+', '/bazel-out/']
            if not ($heuristic_paths | any {|path| $nu_exe =~ $path}) {
                error make {msg: $'nu binary is not from a toolchain: ($nu_exe)'}
            }
            "ok" | save $bazel.outputs.0""",
        outputs = [":nu_exe.out"],
    )

    build_test(
        name = "nu_exe_test",
        targets = [":nu_exe"],
    )
    return "nu_exe_test"

# ── TC-07: Data is available ──────────────────────────────────────────────────

def test_data():
    nu_genrule(
        name = "data",
        cmd = r"""
        let rf = (runfiles create)
        let data = open (runfiles rlocation $rf "_main/data/data1.txt")

        if $data == "Some Data!\n" {
            echo "Ok" | save $bazel.outputs.0
            exit 0
        } else {
            exit 1
        }
        """,
        outputs = [":data.out"],
        data = ["//:data/data1.txt"],
    )

    build_test(
        name = "data_test",
        targets = [":data"],
    )
    return "data_test"

# ── TC-08: Transitive data is available ───────────────────────────────────────

def test_transitive_data():
    nu_library(
        name = "data1",
        srcs = ["//:srcs/a.nu"],
        data = ["//:data/data1.txt"],
    )
    nu_genrule(
        name = "transitive_data",
        cmd = r"""
        let rf = (runfiles create)
        let data = open (runfiles rlocation $rf "_main/data/data1.txt")

        if $data == "Some Data!\n" {
            echo "Ok" | save $bazel.outputs.0
            exit 0
        } else {
            exit 1
        }
        """,
        outputs = [":transitive_data.out"],
        deps = [":data1"],
    )

    build_test(
        name = "transitive_data_test",
        targets = [":transitive_data"],
    )
    return "transitive_data_test"

# ── TC-09: Tools are callable and keep their own runfiles ─────────────────────

def test_tools():
    nu_binary(
        name = "tool",
        main = "//:srcs/tool_data.nu",
        data = ["//:data/data1.txt"],
    )
    nu_genrule(
        name = "tools",
        cmd = r"""
        let out = ^(target location ":tool") | complete
        if $out.exit_code != 0 or $out.stdout != "Some Data!\n" {
            error make {msg: $'unexpected tool result: ($out)'}
        }
        "ok" | save $bazel.outputs.0
        """,
        tools = [":tool"],
        outputs = [":tools.out"],
    )

    build_test(
        name = "tools_test",
        targets = [":tools"],
    )
    return "tools_test"

# ── TC-10: Label spellings resolve to the same file ───────────────────────────

def test_label_spellings():
    nu_binary(
        name = "label_spellings_tool",
        main = "//:srcs/hello.nu",
    )
    nu_genrule(
        name = "label_spellings",
        cmd = r"""
        let canonical = (target location "@@//:fixtures/input.txt")
        for spelling in ["//:fixtures/input.txt"] {
            if (target location $spelling) != $canonical {
                error make {msg: $'($spelling) does not match canonical label'}
            }
        }
        let local = (target location ":label_spellings_tool")
        if $local != (target location "//nu_genrule:label_spellings_tool") {
            error make {msg: "relative and package-absolute labels differ"}
        }
        "ok" | save $bazel.outputs.0
        """,
        inputs = ["//:fixtures/input.txt"],
        tools = [":label_spellings_tool"],
        outputs = [":label_spellings.out"],
    )

    build_test(
        name = "label_spellings_test",
        targets = [":label_spellings"],
    )
    return "label_spellings_test"

# ── TC-11: `target locations` expands a filegroup ─────────────────────────────

def test_locations():
    native.filegroup(
        name = "locations_group",
        srcs = ["//:fixtures/input1.txt", "//:fixtures/input2.txt"],
    )
    nu_genrule(
        name = "locations",
        cmd = r"""
        let files = (target locations ":locations_group")
        if ($files | length) != 2 {
            error make {msg: $'Expected 2 files, got ($files | length)'}
        }
        "ok" | save $bazel.outputs.0
        """,
        inputs = [":locations_group"],
        outputs = [":locations.out"],
    )

    build_test(
        name = "locations_test",
        targets = [":locations"],
    )
    return "locations_test"

# ── TC-12: `target location` errors on multiple files or unknown labels ───────

def test_location_errors():
    native.filegroup(
        name = "location_errors_group",
        srcs = ["//:fixtures/input1.txt", "//:fixtures/input2.txt"],
    )
    nu_genrule(
        name = "location_errors",
        cmd = r"""
        let multi = (try { target location ":location_errors_group"; "no error" } catch {|e| $e.msg })
        if not ($multi | str contains "expected exactly 1") {
            error make {msg: $'unexpected error for multi-file label: ($multi)'}
        }
        let unknown = (try { target location "//:nope"; "no error" } catch {|e| $e.msg })
        if not ($unknown | str contains "unknown label") {
            error make {msg: $'unexpected error for unknown label: ($unknown)'}
        }
        "ok" | save $bazel.outputs.0
        """,
        inputs = [":location_errors_group"],
        outputs = [":location_errors.out"],
    )

    build_test(
        name = "location_errors_test",
        targets = [":location_errors"],
    )
    return "location_errors_test"

# ── TC-13: `data` targets are addressable ─────────────────────────────────────

def test_location_data():
    nu_genrule(
        name = "location_data",
        cmd = r"""
        if (open (target location "//:data/data1.txt")) != "Some Data!\n" {
            error make {msg: "unexpected data1.txt content"}
        }
        "ok" | save $bazel.outputs.0
        """,
        data = ["//:data/data1.txt"],
        outputs = [":location_data.out"],
    )

    build_test(
        name = "location_data_test",
        targets = [":location_data"],
    )
    return "location_data_test"
