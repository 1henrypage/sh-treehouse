#!/usr/bin/env bash

# Test Runner — Sources all test files and prints summary

# Get the directory where this script lives
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

# Add the wt binary to PATH
export PATH="$TEST_DIR/../bin:$PATH"

# Source harness and fixtures
source "$TEST_DIR/harness.sh"
source "$TEST_DIR/fixtures.sh"

# Load bash shell integration so tests can use the wt() wrapper
# (required for cd-capable commands: add, checkout, base)
eval "$(wt init bash)"

# Print TAP version
printf 'TAP version 13\n'

# Source all test files
for test_file in "$TEST_DIR"/test_*.sh; do
  if [ -f "$test_file" ]; then
    source "$test_file"
  fi
done

# Print summary and exit with appropriate code
print_summary
exit $?
