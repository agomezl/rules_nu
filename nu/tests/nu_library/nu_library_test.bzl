"""Analysis tests for the nu_library rule.

Each public macro declares all of its own nu_library fixture targets and its
analysis_test in one place, keeping setup and assertion side-by-side.

Verified properties:
  1. Dependencies appear first when NuInfo.scripts is consumed as a list
     (enforced by the postorder depset order in providers.bzl).
  2. Every transitive dependency is included in NuInfo.scripts but NOT in
     DefaultInfo.files, which carries only the target's direct srcs.
"""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test")
load("@rules_nu//nu:rules.bzl", "nu_library")
load("@rules_nu//nu/private:providers.bzl", "NuInfo")

# ── Shared helpers ────────────────────────────────────────────────────────────

def _script_paths(target):
    """NuInfo.scripts depset as an ordered list of short_paths."""
    return [f.short_path for f in target[NuInfo].scripts.to_list()]

def _default_paths(target):
    """DefaultInfo.files depset as an ordered list of short_paths."""
    return [f.short_path for f in target[DefaultInfo].files.to_list()]

# Stable prefix shared by every expected path assertion.
_S = "nu_library/srcs/"

# ── TC-01: Empty library (no srcs, no deps) ──────────────────────────────────

def test_empty_library():
    nu_library(name = "empty_lib", srcs = [])
    analysis_test(name = "test_empty_library", impl = _test_empty_library_impl, target = "empty_lib")

def _test_empty_library_impl(env, target):
    scripts = _script_paths(target)
    default_files = _default_paths(target)
    if scripts != []:
        env.fail("Expected NuInfo.scripts to be empty, got: %s" % scripts)
    if default_files != []:
        env.fail("Expected DefaultInfo.files to be empty, got: %s" % default_files)

# ── TC-02: Srcs only (no deps) ───────────────────────────────────────────────

def test_srcs_only():
    nu_library(name = "srcs_only_lib", srcs = ["srcs/a.nu"])
    analysis_test(name = "test_srcs_only", impl = _test_srcs_only_impl, target = "srcs_only_lib")

def _test_srcs_only_impl(env, target):
    expected = [_S + "a.nu"]
    scripts = _script_paths(target)
    default_files = _default_paths(target)
    if scripts != expected:
        env.fail("NuInfo.scripts wrong: expected %s, got %s" % (expected, scripts))
    if default_files != expected:
        env.fail("DefaultInfo.files wrong: expected %s, got %s" % (expected, default_files))

# ── TC-03: Single dependency — dep script appears before own script ───────────

def test_single_dep_ordering():
    nu_library(name = "single_dep_a", srcs = ["srcs/a.nu"])
    nu_library(name = "single_dep_b", srcs = ["srcs/b.nu"], deps = ["single_dep_a"])
    analysis_test(name = "test_single_dep_ordering", impl = _test_single_dep_ordering_impl, target = "single_dep_b")

def _test_single_dep_ordering_impl(env, target):
    expected = [_S + "a.nu", _S + "b.nu"]
    scripts = _script_paths(target)
    if len(scripts) != 2:
        env.fail("Expected 2 scripts, got %d: %s" % (len(scripts), scripts))
    if scripts != expected:
        env.fail("Expected ordering %s, got %s" % (expected, scripts))

# ── TC-04: 3-level chain — deepest dep first ─────────────────────────────────

def test_chain_dep_ordering():
    nu_library(name = "chain_a", srcs = ["srcs/a.nu"])
    nu_library(name = "chain_b", srcs = ["srcs/b.nu"], deps = ["chain_a"])
    nu_library(name = "chain_c", srcs = ["srcs/c.nu"], deps = ["chain_b"])
    analysis_test(name = "test_chain_dep_ordering", impl = _test_chain_dep_ordering_impl, target = "chain_c")

def _test_chain_dep_ordering_impl(env, target):
    expected_scripts = [_S + "a.nu", _S + "b.nu", _S + "c.nu"]
    expected_default = [_S + "c.nu"]
    scripts = _script_paths(target)
    if scripts != expected_scripts:
        env.fail("Transitive ordering wrong: expected %s, got %s" % (expected_scripts, scripts))
    default_files = _default_paths(target)
    if default_files != expected_default:
        env.fail("DefaultInfo wrong: expected %s, got %s" % (expected_default, default_files))

# ── TC-05: Diamond — a.nu deduplicated and ordered before b.nu / c.nu ────────

def test_diamond_dep_ordering():
    nu_library(name = "diamond_a", srcs = ["srcs/a.nu"])
    nu_library(name = "diamond_b", srcs = ["srcs/b.nu"], deps = ["diamond_a"])
    nu_library(name = "diamond_c", srcs = ["srcs/c.nu"], deps = ["diamond_a"])
    nu_library(name = "diamond_d", srcs = ["srcs/d.nu"], deps = ["diamond_b", "diamond_c"])
    analysis_test(name = "test_diamond_dep_ordering", impl = _test_diamond_dep_ordering_impl, target = "diamond_d")

def _test_diamond_dep_ordering_impl(env, target):
    expected = [_S + "a.nu", _S + "b.nu", _S + "c.nu", _S + "d.nu"]
    scripts = _script_paths(target)
    if len(scripts) != 4:
        env.fail("Diamond: expected 4 unique scripts, got %d: %s" % (len(scripts), scripts))
    a, b, c, d = _S + "a.nu", _S + "b.nu", _S + "c.nu", _S + "d.nu"
    if a not in scripts:
        env.fail("a.nu missing: %s" % scripts)
        return
    ia, ib = scripts.index(a), scripts.index(b) if b in scripts else len(scripts)
    ic, id_ = scripts.index(c) if c in scripts else len(scripts), scripts.index(d) if d in scripts else len(scripts)
    if not (ia < ib and ia < ic):
        env.fail("a.nu must appear before b.nu and c.nu: %s" % scripts)
    if not (ib < id_ and ic < id_):
        env.fail("b.nu and c.nu must appear before d.nu: %s" % scripts)
    if scripts != expected:
        env.fail("Full ordering mismatch: expected %s, got %s" % (expected, scripts))

# ── TC-06: Explicit deps=[] behaves identically to no deps ───────────────────

def test_empty_deps_list():
    nu_library(name = "empty_deps_lib", srcs = ["srcs/a.nu"], deps = [])
    analysis_test(name = "test_empty_deps_list", impl = _test_empty_deps_list_impl, target = "empty_deps_lib")

def _test_empty_deps_list_impl(env, target):
    expected = [_S + "a.nu"]
    scripts = _script_paths(target)
    default_files = _default_paths(target)
    if scripts != expected:
        env.fail("NuInfo.scripts: expected %s, got %s" % (expected, scripts))
    if default_files != expected:
        env.fail("DefaultInfo.files: expected %s, got %s" % (expected, default_files))

# ── TC-07: DefaultInfo isolation — transitive dep must not appear ─────────────

def test_defaultinfo_isolation_single_dep():
    nu_library(name = "iso_single_a", srcs = ["srcs/a.nu"])
    nu_library(name = "iso_single_b", srcs = ["srcs/b.nu"], deps = ["iso_single_a"])
    analysis_test(name = "test_defaultinfo_isolation_single_dep", impl = _test_defaultinfo_isolation_single_dep_impl, target = "iso_single_b")

def _test_defaultinfo_isolation_single_dep_impl(env, target):
    expected = [_S + "b.nu"]
    forbidden = _S + "a.nu"
    default_files = _default_paths(target)
    if default_files != expected:
        env.fail("DefaultInfo.files: expected %s, got %s" % (expected, default_files))
    if forbidden in default_files:
        env.fail("Transitive dep %s must NOT appear in DefaultInfo.files" % forbidden)

# ── TC-08: DefaultInfo isolation — full diamond, only direct src present ──────

def test_defaultinfo_isolation_transitive():
    nu_library(name = "iso_trans_a", srcs = ["srcs/a.nu"])
    nu_library(name = "iso_trans_b", srcs = ["srcs/b.nu"], deps = ["iso_trans_a"])
    nu_library(name = "iso_trans_c", srcs = ["srcs/c.nu"], deps = ["iso_trans_a"])
    nu_library(name = "iso_trans_d", srcs = ["srcs/d.nu"], deps = ["iso_trans_b", "iso_trans_c"])
    analysis_test(name = "test_defaultinfo_isolation_transitive", impl = _test_defaultinfo_isolation_transitive_impl, target = "iso_trans_d")

def _test_defaultinfo_isolation_transitive_impl(env, target):
    expected = [_S + "d.nu"]
    forbidden = [_S + "a.nu", _S + "b.nu", _S + "c.nu"]
    default_files = _default_paths(target)
    if len(default_files) != 1:
        env.fail("DefaultInfo.files must have exactly 1 file, got %d: %s" % (len(default_files), default_files))
    if default_files != expected:
        env.fail("DefaultInfo.files: expected %s, got %s" % (expected, default_files))
    for f in forbidden:
        if f in default_files:
            env.fail("Transitive file %s must NOT be in DefaultInfo.files" % f)
