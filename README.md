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
bazel_dep(name = "rules_nu", version = "...")
```

A recent version of Nushell for the host platform is fetched from the release database.
To pin a specific version instead, use `nu.toolchain(version = <version>)`.

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

`nu_genrule` is a macro built on top of `nu_binary`: `cmd` is written to a
generated `.nu` script and compiled/run the same way a `nu_binary` would be,
so it also declares two auxiliary targets, `<name>_main` (the generated
script) and `<name>_bin` (the compiled `nu_binary`), alongside `<name>`
itself.
