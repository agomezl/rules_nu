# AGENTS.md

Guidance for agents (and humans) working in this repo.

## What this is

`rules_nu` provides Bazel rules (`nu_library`, `nu_binary`, `nu_genrule`) for
using [Nushell](https://github.com/nushell/nushell) as a build/glue language.
See `README.md` for the rule reference and `TOOLCHAINS.md` for toolchain
details.

## Design principles

- **Simple.** Prefer the smallest rule/interface that covers the use case.
  Don't add options or abstractions speculatively — the three rules
  (`nu_library`, `nu_binary`, `nu_genrule`) are meant to stay easy to
  understand end to end.
- **Hermetic.** Nushell is fetched and managed via a Bazel toolchain; rules
  and tests should not depend on a system-wide install or other ambient state
  on the host. Keep changes consistent with this — avoid introducing
  non-hermetic dependencies (network access at build time, host tool
  assumptions, etc.).

## Repo layout

- `nu/` — public rule definitions (`nu/rules.bzl`) and implementations
  (`nu/private/`), plus toolchain setup (`nu/toolchains/`).
- `tests/rules/` — Bazel test workspace exercising `nu_library`, `nu_binary`,
  and `nu_genrule`.
- `tests/bcr/` — Bazel Central Registry presubmit checks.
- `examples/` — example usages of the rules.
- `tools/` — release and validation scripts.

## Testing

Rule changes are tested in the `tests/rules` workspace, not the root
workspace:

```sh
cd tests/rules
bazel test //...
```

Run this after any change to `nu/` before considering the change done.
