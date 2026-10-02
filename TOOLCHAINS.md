# Toolchain setup

## Default: latest release

```python
nu = use_extension("@rules_nu//nu:extensions.bzl", "nu")
use_repo(nu, "nu_toolchains")
register_toolchains("@nu_toolchains//:all")
```

With no tags, the latest Nushell release for the host platform is used. There
is no version list in `rules_nu`: archive hashes are read from the
`SHA256SUMS` file published with each Nushell release and stored as module
extension *facts* in `MODULE.bazel.lock`. Later builds use the locked version
and hashes without network access. To move to a newer release, refresh the
lockfile entry (e.g. remove the `//nu:extensions.bzl%nu` entry under `facts`
and run `bazel mod deps`).

## Pinned version

```python
nu.toolchain(version = "0.114.0")
```

## Multi-platform / remote execution

`nu.toolchain` defaults to the host platform. For heterogeneous execution
platforms, add one tag per platform (`version` may be omitted for latest):

```python
nu.toolchain(os = "linux",    arch = "x86_64")
nu.toolchain(os = "linux",    arch = "aarch64")
nu.toolchain(os = "mac os x", arch = "aarch64", version = "0.114.0")
```

Bazel picks the matching toolchain from `@nu_toolchains` at build time.
Supported platforms: Linux, macOS and Windows on x86_64, plus aarch64 on
Linux and macOS.

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
