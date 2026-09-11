#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
Rscript "$ROOT_DIR/tests/run_smoke_test.R"
