#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

rm -rf "$ROOT/artifacts"
mkdir -p "$ROOT/artifacts"

cd "$ROOT"

zip -r artifacts/bootstrap.zip powershell