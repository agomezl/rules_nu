# Load the nushell_toolchain rule
load(":defs.bzl", "nushell_toolchain")

# Nushell toolchain type
toolchain_type(
    name = "type",
    visibility = ["//visibility:public"],
)

# Default nushell toolchain target
# Update the 'nu' attribute to point to your actual nushell binary
nushell_toolchain(
    name = "nushell_toolchain",
    nu = "@local_nu//:nu",
)

toolchain(
    name = "local_nu",
    toolchain = ":nushell_toolchain",
    toolchain_type = ":toolchain_type",
)
