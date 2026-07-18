# rules_nu

> **⚠️ Early stage** — This project is under active development. APIs may change
> without notice.

Bazel rules for [Nushell](https://github.com/nushell/nushell). The main goal is
to provide an alternative "glue" scripting language for Bazel that does not fall
into the same pitfalls as Bash or Python. We focus on three principles:

- **Hermetic and self-contained** — Nushell is fetched and managed through the
  Bazel toolchain; no system-wide install required.
- **Simple rules and interface** — `nu_library`, `nu_binary`, and `nu_genrule`
  cover the common use cases.
- **Built-in alternatives to common tools** — Nushell ships with capable
  replacements for `wget`, `grep`, `sed`, and more, reducing the need for
  external dependencies in your build.

## Rules

| Rule         | Purpose                                                                  |
| ------------ | ------------------------------------------------------------------------ |
| `nu_library` | Collects `.nu` source files into a reusable module.                      |
| `nu_binary`  | Builds an executable that runs a `.nu` script with Nushell.              |
| `nu_genrule` | Runs an inline Nushell command during the build to produce output files. |

## Setup

```python
bazel_dep(name = "rules_nu", version = "0.1.0")

nu = use_extension("@rules_nu//nu:extensions.bzl", "nu")
nu.latest()
use_repo(nu, "nu_toolchains")
register_toolchains("@nu_toolchains//:all")
```

`nu.latest()` fetches the most recent Nushell version in the release database
for the host platform. To pin a specific version instead, use
`nu.toolchain(version = <version>)`.

For multi-platform builds and custom binaries, see [TOOLCHAINS.md](TOOLCHAINS.md).

## Usage

```python
load("@rules_nu//nu:rules.bzl", "nu_binary", "nu_genrule", "nu_library")

nu_library(
    name = "utils",
    srcs = ["utils.nu"],
)

nu_binary(
    name = "hello",
    main = "hello.nu",
    deps = [":utils"],
)

nu_genrule(
    name = "greeting",
    cmd = """echo "Hello!" | save ($bazel.outputs | get 0)""",
    outputs = ["greeting.txt"],
)
```
