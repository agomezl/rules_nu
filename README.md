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

Add `rules_nu` to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_nu", version = "0.1.0")
```

Then register a Nushell toolchain (see `MODULE.bazel` in this repo for an
example).

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
