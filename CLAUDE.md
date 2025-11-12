# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Bash utility script that helps users find shell aliases for commands they type. The script can be sourced in `.bashrc` or `.bash_profile` to make the `alias-finder` function available.

## Key Architecture

The project consists of a single Bash script (`alias-finder.sh`) with two main functions:

- `alias-finder()`: Core function that searches through defined aliases using grep/ripgrep
  - Supports exact matching, longer matching, and "cheaper" (shorter) alias matching
  - Iteratively removes words from the end of the command to find partial matches
  - Uses regex patterns to match against the output of the `alias` command

- `alias-finder-preexec()`: Optional hook function for automatic alias suggestions
  - Requires `bash-preexec` library to be loaded
  - Automatically suggests aliases before command execution when `ALIAS_FINDER_AUTOMATIC=true`

## Configuration

The script accepts both command-line flags and environment variables:

- `-e|--exact` or `ALIAS_FINDER_EXACT=true`: Only show exact matches
- `-l|--longer` or `ALIAS_FINDER_LONGER=true`: Show longer aliases
- `-c|--cheaper` or `ALIAS_FINDER_CHEAPER=true`: Show shorter aliases only
- `ALIAS_FINDER_AUTOMATIC=true`: Enable automatic suggestions (requires bash-preexec)

## Testing

To test changes, source the script in a bash shell:
```bash
source alias-finder.sh
alias-finder "git status"
```

## Dependencies

- Bash shell
- Optional: `ripgrep` (rg) for faster searching, falls back to `grep`
- Optional: `bash-preexec` for automatic alias suggestions
