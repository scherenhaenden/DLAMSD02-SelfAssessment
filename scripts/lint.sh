#!/usr/bin/env bash
set -euo pipefail

# AssessYourself Code Quality & Style Verification Script (DLAMSD02)
# Runs SwiftLint and swift-format to ensure strict code quality, architecture compliance and formatting.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo "=========================================================="
echo "AssessYourself: Code Quality & Style Verification (DLAMSD02)"
echo "=========================================================="

# 1. SwiftLint (Mandatory strict static analysis)
if command -v swiftlint >/dev/null 2>&1; then
    echo "--> Running SwiftLint (--strict --no-cache)..."
    swiftlint lint --strict --no-cache
    echo "✓ SwiftLint passed with 0 violations."
else
    echo "❌ SwiftLint not found on PATH. Run 'brew install swiftlint' to install."
    exit 1
fi

# 2. swift-format (Apple Xcode toolchain advisory check)
SWIFT_FORMAT="$(xcrun --find swift-format 2>/dev/null || true)"
if [ -n "${SWIFT_FORMAT}" ] && [ -x "${SWIFT_FORMAT}" ]; then
    echo "--> Running Apple swift-format advisory lint..."
    "${SWIFT_FORMAT}" lint --recursive src ui-tests >/dev/null 2>&1 || true
    echo "✓ Apple swift-format lint completed (advisory)."
fi

echo "=========================================================="
echo "All mandatory code quality and linting checks passed successfully!"
echo "=========================================================="
