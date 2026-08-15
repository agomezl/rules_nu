load("@rules_nu//nu:rules.bzl", "nu_library")

exports_files(glob(["data/*"]))

nu_library(
    name = "math",
    srcs = ["modules/math.nu"],
    visibility = ["//:__subpackages__"],
)
