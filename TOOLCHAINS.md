# Toolchain setup

## Basic setup

Add `rules_nu` to your `MODULE.bazel` and register a toolchain:

```python
bazel_dep(name = "rules_nu", version = "0.1.0")

nu = use_extension("@rules_nu//nu:extensions.bzl", "nu")
nu.toolchain(version = "0.114.0")
use_repo(nu, "nu_toolchains")
register_toolchains("@nu_toolchains//:all")
```

The `nu.toolchain` tag fetches the correct Nushell binary for the host
platform automatically. Supported versions are listed in
[`nu/private/extensions/defs.bzl`](nu/private/extensions/defs.bzl).

## Multi-platform / remote execution

By default, `nu.toolchain` resolves to the host platform. For builds with
heterogeneous execution platforms (e.g. mixed Linux and macOS remote workers),
add one `nu.toolchain` tag per target platform:

```python
nu.toolchain(version = "0.114.0")  # host platform
nu.toolchain(version = "0.114.0", os = "linux",    arch = "x86_64")
nu.toolchain(version = "0.114.0", os = "linux",    arch = "aarch64")
nu.toolchain(version = "0.114.0", os = "mac os x", arch = "aarch64")
```

Each extra tag registers an additional toolchain in `@nu_toolchains`; Bazel
picks the right one at build time based on the execution platform.

## Custom binary

To bring your own Nushell binary (e.g. a patched build), use `nu.url`:

```python
nu.url(
    name = "my_nu",
    url = "https://example.com/nu-custom.tar.gz",
    sha256 = "...",
    nu_path = "nu-custom/nu",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
)
```
