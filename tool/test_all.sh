#!/usr/bin/env bash
# Run tests across every package in the workspace.
#
# Flutter packages use `flutter test`, pure Dart packages use `dart test`.
# Detection: any package with an `ios/` or `android/` dir OR depending on
# `flutter` is treated as a Flutter package.
#
# Usage:
#   ./tool/test_all.sh                # run all packages
#   ./tool/test_all.sh editor docx    # run a subset (matching folder name)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
cd "$ROOT"

# Default package list — dependency order so failures in core surface first.
DEFAULT_PKGS=(
  quill_delta_core
  quill_delta_html
  quill_delta_markdown
  quill_delta_docx
  quill_delta_pdf
  quill_delta_editor
  _e2e_tests
)

if (( $# > 0 )); then
  PKGS=("$@")
else
  PKGS=("${DEFAULT_PKGS[@]}")
fi

passed=()
failed=()

for raw in "${PKGS[@]}"; do
  # Accept either short name (editor) or full prefixed (quill_delta_editor).
  if [[ -d "packages/$raw" ]]; then
    dir="packages/$raw"
  elif [[ -d "packages/quill_delta_$raw" ]]; then
    dir="packages/quill_delta_$raw"
  else
    echo "skip: no package named $raw"
    continue
  fi

  if [[ ! -d "$dir/test" ]]; then
    echo "skip: $dir has no test/ dir"
    continue
  fi

  echo
  echo "=========================================="
  echo "  $dir"
  echo "=========================================="

  cmd=(dart test)
  if grep -q "flutter:" "$dir/pubspec.yaml" 2>/dev/null; then
    cmd=(flutter test)
  fi

  if (cd "$dir" && "${cmd[@]}"); then
    passed+=("$dir")
  else
    failed+=("$dir")
  fi
done

echo
echo "=========================================="
echo "  Summary"
echo "=========================================="
# `set -u` rejects empty array expansions with "${arr[@]}"; guard with the
# `${arr[@]+...}` parameter expansion so empty results are safe.
for p in ${passed[@]+"${passed[@]}"}; do echo "  pass  $p"; done
for p in ${failed[@]+"${failed[@]}"}; do echo "  FAIL  $p"; done

if (( ${#failed[@]} > 0 )); then
  exit 1
fi
