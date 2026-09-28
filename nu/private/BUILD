exports_files([
    "config.nu",
    "env.nu",
])

# Only used to generate the docs in //docs.
filegroup(
    name = "bzl_srcs",
    srcs = glob(["*.bzl"]),
    visibility = ["//docs:__pkg__"],
)
