#!/usr/bin/env bash
#
# test.sh - Test suite for alias-finder.sh
#
# Comprehensive tests for alias-finder functionality
# Run with: bash test.sh

set -e

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the script to test
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/alias-finder.sh" || exit 1

#######################################
# Print test result
#######################################
pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  printf "${GREEN}✓${NC} %s\n" "$1"
}

fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf "${RED}✗${NC} %s\n" "$1"
  [[ -n "${2:-}" ]] && printf "  ${YELLOW}%s${NC}\n" "$2"
}

#######################################
# Test helper functions
#######################################
test_helper_functions() {
  printf "\n${YELLOW}Testing helper functions...${NC}\n"

  # Test _alias_finder_escape_regex
  local result
  result=$(_alias_finder_escape_regex "test.txt")
  if [[ "$result" == "test\\.txt" ]]; then
    pass "_alias_finder_escape_regex escapes dots"
  else
    fail "_alias_finder_escape_regex escapes dots" "Got: $result"
  fi

  result=$(_alias_finder_escape_regex "test|pipe")
  if [[ "$result" == "test\\|pipe" ]]; then
    pass "_alias_finder_escape_regex escapes pipes"
  else
    fail "_alias_finder_escape_regex escapes pipes" "Got: $result"
  fi

  # Test _alias_finder_normalize_cmd
  result=$(_alias_finder_normalize_cmd "test  multiple   spaces")
  if [[ "$result" == "test multiple spaces" ]]; then
    pass "_alias_finder_normalize_cmd normalizes spaces"
  else
    fail "_alias_finder_normalize_cmd normalizes spaces" "Got: $result"
  fi

  # Test _alias_finder_has_command
  if _alias_finder_has_command bash; then
    pass "_alias_finder_has_command finds bash"
  else
    fail "_alias_finder_has_command finds bash"
  fi

  if ! _alias_finder_has_command nonexistent_command_xyz_12345; then
    pass "_alias_finder_has_command rejects invalid command"
  else
    fail "_alias_finder_has_command rejects invalid command"
  fi
}

#######################################
# Test basic functionality
#######################################
test_basic_functionality() {
  printf "\n${YELLOW}Testing basic functionality...${NC}\n"

  # Set up test aliases
  alias testgs='git status'
  alias testgc='git commit'
  alias testgl='git log'

  # Test finding exact match
  if alias-finder git status 2>/dev/null | grep -q "testgs='git status'"; then
    pass "Find alias by exact command"
  else
    fail "Find alias by exact command"
  fi

  # Test partial match
  if alias-finder git 2>/dev/null | grep -q "testgs"; then
    pass "Find alias by partial command"
  else
    fail "Find alias by partial command"
  fi

  # Clean up test aliases
  unalias testgs testgc testgl 2>/dev/null || true
}

#######################################
# Test command-line options
#######################################
test_command_line_options() {
  printf "\n${YELLOW}Testing command-line options...${NC}\n"

  # Test --help
  if alias-finder --help 2>/dev/null | grep -q "USAGE"; then
    pass "--help displays usage"
  else
    fail "--help displays usage"
  fi

  # Test -h
  if alias-finder -h 2>/dev/null | grep -q "USAGE"; then
    pass "-h displays usage"
  else
    fail "-h displays usage"
  fi

  # Test no arguments shows help
  if alias-finder 2>/dev/null | grep -q "USAGE"; then
    pass "No arguments displays usage"
  else
    fail "No arguments displays usage"
  fi

  # Test invalid option
  if ! alias-finder --invalid-option 2>/dev/null; then
    pass "Invalid option returns error"
  else
    fail "Invalid option returns error"
  fi

  # Set up test alias for option tests
  alias testopt='echo hello'

  # Test --exact option
  if alias-finder --exact "echo hello" 2>/dev/null | grep -q "testopt"; then
    pass "--exact finds exact match"
  else
    fail "--exact finds exact match"
  fi

  # Test -e option
  if alias-finder -e "echo hello" 2>/dev/null | grep -q "testopt"; then
    pass "-e finds exact match"
  else
    fail "-e finds exact match"
  fi

  # Clean up
  unalias testopt 2>/dev/null || true
}

#######################################
# Test environment variables
#######################################
test_environment_variables() {
  printf "\n${YELLOW}Testing environment variables...${NC}\n"

  # Set up test alias
  alias testenv='echo test'

  # Test ALIAS_FINDER_EXACT
  if ALIAS_FINDER_EXACT=true alias-finder "echo test" 2>/dev/null | grep -q "testenv"; then
    pass "ALIAS_FINDER_EXACT works"
  else
    fail "ALIAS_FINDER_EXACT works"
  fi

  # Clean up
  unalias testenv 2>/dev/null || true
}

#######################################
# Test edge cases
#######################################
test_edge_cases() {
  printf "\n${YELLOW}Testing edge cases...${NC}\n"

  # Test with special characters in command
  alias testspecial='echo $PATH'
  if alias-finder 'echo $PATH' 2>/dev/null | grep -q "testspecial"; then
    pass "Handle special characters in command"
  else
    fail "Handle special characters in command"
  fi
  unalias testspecial 2>/dev/null || true

  # Test with quotes
  alias testquote='echo "hello"'
  if alias-finder 'echo' 2>/dev/null | grep -q "testquote"; then
    pass "Handle quotes in alias (partial match)"
  else
    fail "Handle quotes in alias (partial match)"
  fi
  unalias testquote 2>/dev/null || true

  # Test command with pipes
  alias testpipe='ls | grep test'
  if alias-finder 'ls' 2>/dev/null | grep -q "testpipe"; then
    pass "Handle pipes in alias (partial match)"
  else
    fail "Handle pipes in alias (partial match)"
  fi
  unalias testpipe 2>/dev/null || true
}

#######################################
# Test search functionality
#######################################
test_search_functionality() {
  printf "\n${YELLOW}Testing search functionality...${NC}\n"

  # Set up test aliases
  alias short='git status'
  alias longer_alias='git'

  # Test that search finds aliases
  if _alias_finder_search "" "'{0,1}git"; then
    pass "_alias_finder_search finds matches"
  else
    fail "_alias_finder_search finds matches"
  fi

  # Test that search returns false for non-existent pattern
  if ! _alias_finder_search "" "'{0,1}nonexistent_xyz_99999"; then
    pass "_alias_finder_search returns false for no matches"
  else
    fail "_alias_finder_search returns false for no matches"
  fi

  # Clean up
  unalias short longer_alias 2>/dev/null || true
}

#######################################
# Test preexec functionality
#######################################
test_preexec_functionality() {
  printf "\n${YELLOW}Testing preexec functionality...${NC}\n"

  # Test preexec with ALIAS_FINDER_AUTOMATIC disabled
  if ALIAS_FINDER_AUTOMATIC=false alias-finder-preexec "git status" 2>/dev/null; then
    pass "alias-finder-preexec returns success when disabled"
  else
    fail "alias-finder-preexec returns success when disabled"
  fi

  # Test preexec with empty command
  if ALIAS_FINDER_AUTOMATIC=true alias-finder-preexec "" 2>/dev/null; then
    pass "alias-finder-preexec handles empty command"
  else
    fail "alias-finder-preexec handles empty command"
  fi
}

#######################################
# Print summary
#######################################
print_summary() {
  printf "\n${YELLOW}═══════════════════════════════════════${NC}\n"
  printf "${YELLOW}Test Summary${NC}\n"
  printf "${YELLOW}═══════════════════════════════════════${NC}\n"
  printf "Total tests:  %d\n" "$TESTS_RUN"
  printf "${GREEN}Passed:       %d${NC}\n" "$TESTS_PASSED"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    printf "${RED}Failed:       %d${NC}\n" "$TESTS_FAILED"
  else
    printf "Failed:       %d\n" "$TESTS_FAILED"
  fi

  if [[ $TESTS_FAILED -eq 0 ]]; then
    printf "\n${GREEN}✓ All tests passed!${NC}\n"
    return 0
  else
    printf "\n${RED}✗ Some tests failed${NC}\n"
    return 1
  fi
}

#######################################
# Main test execution
#######################################
main() {
  printf "${YELLOW}═══════════════════════════════════════${NC}\n"
  printf "${YELLOW}alias-finder Test Suite${NC}\n"
  printf "${YELLOW}═══════════════════════════════════════${NC}\n"

  test_helper_functions
  test_basic_functionality
  test_command_line_options
  test_environment_variables
  test_edge_cases
  test_search_functionality
  test_preexec_functionality

  print_summary
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
