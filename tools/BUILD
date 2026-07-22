load("@bazelrc-preset.bzl", "bazelrc_preset")
load("//nu:rules.bzl", "nu_binary")

bazelrc_preset(
    name = "preset",
    tags = ["manual"],
)

nu_binary(
    name = "release",
    main = "release.nu",
)
