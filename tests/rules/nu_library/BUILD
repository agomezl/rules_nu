load(
    ":nu_library_test.bzl",
    "test_chain_dep_ordering",
    "test_defaultinfo_isolation_single_dep",
    "test_defaultinfo_isolation_transitive",
    "test_diamond_dep_ordering",
    "test_empty_deps_list",
    "test_empty_library",
    "test_single_dep_ordering",
    "test_srcs_only",
)

test_empty_library()

test_srcs_only()

test_single_dep_ordering()

test_chain_dep_ordering()

test_diamond_dep_ordering()

test_empty_deps_list()

test_defaultinfo_isolation_single_dep()

test_defaultinfo_isolation_transitive()

test_suite(
    name = "tests",
    tests = [
        ":test_empty_library",
        ":test_srcs_only",
        ":test_single_dep_ordering",
        ":test_chain_dep_ordering",
        ":test_diamond_dep_ordering",
        ":test_empty_deps_list",
        ":test_defaultinfo_isolation_single_dep",
        ":test_defaultinfo_isolation_transitive",
    ],
    visibility = ["//visibility:public"],
)
