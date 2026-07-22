#!/usr/bin/env bash
set -euo pipefail

# Bash? please.
bazel --noworkspace_rc run //tools:release -- $*
