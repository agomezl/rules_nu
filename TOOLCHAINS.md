# Toolchain setup

## Latest version (simplest)

When you add `rules_nu` to your `MODULE.bazel`, it picks the newest available
version automatically using `nu.latest()`:

```python
nu = use_extension("@rules_nu//nu:extensions.bzl", "nu")
nu.latest()
use_repo(nu, "nu_toolchains")
register_toolchains("@nu_toolchains//:all")
```

`nu.latest()` resolves to the latest Nushell release the first time it is
evaluated. The resolved version and the archive hashes (read from the
release's `SHA256SUMS`) are recorded as facts in `MODULE.bazel.lock`, so later
builds are reproducible and need no extra lookup. To move to a newer release,
remove the `//nu:extensions.bzl%nu` entry under `facts` in the lockfile and
run `bazel mod deps`. The correct binary for the host platform is fetched
automatically.

## Pinned version

To lock to a specific Nushell release, use `nu.toolchain` with an explicit
version.

```python
bazel_dep(name = "rules_nu", version = "0.1.0")

nu = use_extension("@rules_nu//nu:extensions.bzl", "nu")
nu.toolchain(version = "0.114.0")
use_repo(nu, "nu_toolchains")
register_toolchains("@nu_toolchains//:all")
```

Any released version can be used; its hashes are fetched from the release and
recorded in `MODULE.bazel.lock`.

## Multi-platform / remote execution

Both `nu.latest` and `nu.toolchain` default to the host platform. For builds
with heterogeneous execution platforms (e.g. mixed Linux and macOS remote
workers), add one tag per target platform:

```python
nu.latest()  # host platform
nu.latest(os = "linux",    arch = "x86_64")
nu.latest(os = "linux",    arch = "aarch64")
nu.latest(os = "mac os x", arch = "aarch64")
```

Or with an explicit pinned version:

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
