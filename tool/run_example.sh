#!/usr/bin/env bash
# Run the editor example app from the repo root.
#
# Usage:
#   ./tool/run_example.sh            # debug on default device
#   ./tool/run_example.sh -d chrome  # any flag forwarded to flutter run
#   ./tool/run_example.sh --release
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../packages/quill_delta_editor/example"
exec flutter run "$@"
