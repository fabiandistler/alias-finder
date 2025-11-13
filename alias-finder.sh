#!/usr/bin/env bash
#
# alias-finder.sh - Find and suggest shell aliases for commands
#
# A Bash utility that helps users discover existing aliases for commands they type.
# Can be sourced in .bashrc/.bash_profile for interactive use or with automatic
# suggestions via bash-preexec integration.
#
# Author: alias-finder contributors
# License: MIT
# Version: 2.0.0

# Prevent sourcing multiple times
[[ -n "${ALIAS_FINDER_LOADED:-}" ]] && return 0
readonly ALIAS_FINDER_LOADED=1

#######################################
# Display usage information and help
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes usage information to stdout
#######################################
alias-finder-help() {
  cat <<'EOF'
alias-finder - Find shell aliases for commands

USAGE:
  alias-finder [OPTIONS] <command>

OPTIONS:
  -e, --exact     Show only exact matches (no partial matches)
  -l, --longer    Show aliases that are longer than the command
  -c, --cheaper   Show only aliases shorter than the command
  -h, --help      Display this help message

ENVIRONMENT VARIABLES:
  ALIAS_FINDER_EXACT      Set to 'true' to enable exact matching (default: false)
  ALIAS_FINDER_LONGER     Set to 'true' to show longer aliases (default: false)
  ALIAS_FINDER_CHEAPER    Set to 'true' to show only cheaper aliases (default: false)
  ALIAS_FINDER_AUTOMATIC  Set to 'true' to enable automatic suggestions (requires bash-preexec)

EXAMPLES:
  # Find aliases for 'git status'
  alias-finder git status

  # Find exact matches only
  alias-finder --exact "git commit"

  # Find shorter aliases only
  alias-finder --cheaper "git log --oneline"

  # Enable automatic suggestions (in .bashrc)
  export ALIAS_FINDER_AUTOMATIC=true
  source bash-preexec.sh
  source alias-finder.sh

NOTES:
  - Uses ripgrep (rg) if available, falls back to grep
  - Automatically searches for partial matches unless --exact is specified
  - Requires bash-preexec for automatic suggestion feature

EOF
}

#######################################
# Escape special regex characters in a string
# Globals:
#   None
# Arguments:
#   $1 - String to escape
# Outputs:
#   Writes escaped string to stdout
# Returns:
#   0 on success
#######################################
_alias_finder_escape_regex() {
  local input="$1"
  # Escape special regex characters: . \ | $ ( ) { } ? + * ^ [ ]
  printf '%s' "$input" | sed 's/[].\|$(){}?+*^[]/\\&/g'
}

#######################################
# Normalize whitespace in command string
# Globals:
#   None
# Arguments:
#   $1 - Command string to normalize
# Outputs:
#   Writes normalized string to stdout
# Returns:
#   0 on success
#######################################
_alias_finder_normalize_cmd() {
  local input="$1"
  # Convert newlines to spaces, trim, and collapse multiple spaces
  # Use sed instead of xargs to avoid potential hanging issues
  printf '%s' "$input" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -s '[:space:]'
}

#######################################
# Check if a command exists in PATH
# Globals:
#   None
# Arguments:
#   $1 - Command name to check
# Returns:
#   0 if command exists, 1 otherwise
#######################################
_alias_finder_has_command() {
  command -v "$1" &>/dev/null
}

#######################################
# Search for aliases using the best available tool
# Globals:
#   None
# Arguments:
#   $1 - Filter pattern (optional, can be empty)
#   $2 - Finder pattern (required)
# Outputs:
#   Writes matching aliases to stdout
# Returns:
#   0 if matches found, 1 otherwise
#######################################
_alias_finder_search() {
  local filter="$1"
  local finder="$2"
  local result

  if _alias_finder_has_command rg; then
    # Use ripgrep for faster searching
    if [[ -n "$filter" ]]; then
      result=$(alias | rg "$filter" | rg "=$finder" 2>/dev/null)
    else
      result=$(alias | rg "=$finder" 2>/dev/null)
    fi
  else
    # Fall back to grep
    if [[ -n "$filter" ]]; then
      result=$(alias | grep -E "$filter" | grep -E "=$finder" 2>/dev/null)
    else
      result=$(alias | grep -E "=$finder" 2>/dev/null)
    fi
  fi

  if [[ -n "$result" ]]; then
    printf '%s\n' "$result"
    return 0
  fi
  return 1
}

#######################################
# Find aliases for a given command
# Globals:
#   ALIAS_FINDER_EXACT
#   ALIAS_FINDER_LONGER
#   ALIAS_FINDER_CHEAPER
# Arguments:
#   Command-line options and command to search
# Outputs:
#   Writes matching aliases to stdout
# Returns:
#   0 on success
#######################################
alias-finder() {
  # Handle help flag first
  if [[ $# -eq 0 ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    alias-finder-help
    return 0
  fi

  # Initialize variables
  local cmd="" exact=false longer=false cheaper=false
  local finder="" filter=""

  # Parse command-line arguments
  local arg
  for arg in "$@"; do
    case "$arg" in
      -e|--exact)
        exact=true
        ;;
      -l|--longer)
        longer=true
        ;;
      -c|--cheaper)
        cheaper=true
        ;;
      -h|--help)
        alias-finder-help
        return 0
        ;;
      -*)
        printf 'Error: Unknown option: %s\n' "$arg" >&2
        printf 'Use --help for usage information.\n' >&2
        return 1
        ;;
      *)
        cmd="${cmd}${arg} "
        ;;
    esac
  done

  # Override with environment variables
  [[ "${ALIAS_FINDER_EXACT:-false}" == "true" ]] && exact=true
  [[ "${ALIAS_FINDER_LONGER:-false}" == "true" ]] && longer=true
  [[ "${ALIAS_FINDER_CHEAPER:-false}" == "true" ]] && cheaper=true

  # Validate that we have a command to search
  if [[ -z "${cmd// /}" ]]; then
    printf 'Error: No command specified\n' >&2
    printf 'Use --help for usage information.\n' >&2
    return 1
  fi

  # Normalize and escape the command for regex matching
  cmd=$(_alias_finder_normalize_cmd "$cmd")
  cmd=$(_alias_finder_escape_regex "$cmd")

  # Search for aliases
  local found=false
  local is_first_iteration=true
  while [[ -n "$cmd" ]]; do
    # Build finder pattern
    # For first iteration with exact/longer off, match command precisely
    # For subsequent iterations or with longer flag, allow text after command
    if [[ "$is_first_iteration" == true ]] && [[ "$exact" == true ]]; then
      # Exact mode: match the exact command with optional quotes at start/end
      finder="'?${cmd}'?\$"
    elif [[ "$longer" == true ]]; then
      # Longer mode: match command anywhere (allows longer aliases)
      finder="${cmd}"
    else
      # Default: match command at start, allow more text after (partial matching)
      finder="'?${cmd}"
    fi
    is_first_iteration=false

    # Apply cheaper (shorter) filter if requested
    if [[ "$cheaper" == true ]]; then
      local cmd_len=${#cmd}
      # Don't search for aliases if command is too short
      [[ $cmd_len -le 1 ]] && break
      filter="^'?.{1,$((cmd_len - 1))}'?="
    fi

    # Perform the search
    if _alias_finder_search "$filter" "$finder"; then
      found=true
    fi

    # Break if exact or longer match mode (no iterative shortening)
    [[ "$exact" == true || "$longer" == true ]] && break

    # Remove the last word and try again
    cmd=$(printf '%s' "$cmd" | sed -E 's/ {0,}[^ ]*$//')
  done

  # Return success if we found any matches
  [[ "$found" == true ]] && return 0
  return 1
}

#######################################
# Preexec hook for automatic alias suggestions
# Requires bash-preexec library
# Globals:
#   ALIAS_FINDER_AUTOMATIC
# Arguments:
#   $1 - Command about to be executed
# Outputs:
#   Writes alias suggestions to stdout if found
#######################################
alias-finder-preexec() {
  # Only run if automatic mode is enabled
  [[ "${ALIAS_FINDER_AUTOMATIC:-false}" != "true" ]] && return 0

  # Skip empty commands
  [[ -z "${1:-}" ]] && return 0

  # Run alias-finder and suppress its return code
  alias-finder "$1" 2>/dev/null || true
}

#######################################
# Initialize automatic alias suggestions if enabled
# Globals:
#   ALIAS_FINDER_AUTOMATIC
#   preexec_functions
# Arguments:
#   None
# Outputs:
#   Writes warning to stderr if bash-preexec is not loaded
#######################################
_alias_finder_init_automatic() {
  [[ "${ALIAS_FINDER_AUTOMATIC:-false}" != "true" ]] && return 0

  # Check if bash-preexec is loaded
  if declare -p preexec_functions &>/dev/null; then
    # Add our function to the preexec array if not already present
    local func
    for func in "${preexec_functions[@]:-}"; do
      [[ "$func" == "alias-finder-preexec" ]] && return 0
    done
    preexec_functions+=(alias-finder-preexec)
  else
    printf 'Warning: ALIAS_FINDER_AUTOMATIC is enabled but bash-preexec is not loaded.\n' >&2
    printf 'Please source bash-preexec.sh before this script.\n' >&2
    printf 'Download from: https://github.com/rcaloras/bash-preexec\n' >&2
  fi
}

# Initialize automatic mode if enabled
_alias_finder_init_automatic

# Export main function for subshells (optional)
export -f alias-finder 2>/dev/null || true
