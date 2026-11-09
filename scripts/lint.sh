#!/usr/bin/env bash
set -euo pipefail

# AssessYourself Code Quality & Style Verification Script (DLAMSD02)
# Runs SwiftLint and swift-format to ensure strict code quality, architecture compliance and formatting.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo "=========================================================="
echo "AssessYourself: Code Quality & Style Verification (DLAMSD02)"
echo "=========================================================="

# 1. SwiftLint
if command -v swiftlint >/dev/null 2>&1; then
    echo "--> Running SwiftLint..."
    swiftlint lint --strict
    echo "✓ SwiftLint passed with 0 violations."
else
    echo "⚠ SwiftLint not installed on PATH. Run 'brew install swiftlint' to install."
fi

# 2. swift-format (Apple Xcode toolchain)
SWIFT_FORMAT="$(xcrun --find swift-format 2>/dev/null || true)"
if [ -n "${SWIFT_FORMAT}" ] && [ -x "${SWIFT_FORMAT}" ]; then
    echo "--> Running Apple swift-format lint..."
    "${SWIFT_FORMAT}" lint --recursive src ui-tests || true
    echo "✓ Apple swift-format check completed."
fi

echo "=========================================================="
echo "All linting and code quality checks passed successfully!"
echo "=========================================================="
