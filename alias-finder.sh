# Alias Finder for Bash
alias-finder() {
  local cmd="" exact=false longer=false cheaper=false wordEnd="'{0,1}\$" finder="" filter=""

  # Build command and options
  for c in "$@"; do
    case "$c" in
      -e|--exact) exact=true ;;
      -l|--longer) longer=true ;;
      -c|--cheaper) cheaper=true ;;
      *) cmd="$cmd$c " ;;
    esac
  done

  # Alternative to zstyle: environment variables
  [[ "${ALIAS_FINDER_LONGER:-false}" == "true" ]] && longer=true
  [[ "${ALIAS_FINDER_EXACT:-false}" == "true" ]] && exact=true
  [[ "${ALIAS_FINDER_CHEAPER:-false}" == "true" ]] && cheaper=true

  # Format cmd for grep
  cmd=$(echo -n "$cmd" | tr '\n' ' ' | xargs | tr -s '[:space:]' | sed 's/[].\|$(){}?+*^[]/\\&/g')

  [[ "$longer" == true ]] && wordEnd=""

  # Find aliases
  while [[ -n "$cmd" ]]; do
    finder="'{0,1}$cmd$wordEnd"

    if [[ "$cheaper" == true ]]; then
      local cmdLen=${#cmd}
      [[ $cmdLen -le 1 ]] && return
      filter="^'\\?.\\{1,$((cmdLen - 1))\\}'\\?="
    fi

    if command -v rg &> /dev/null; then
      alias | rg ${filter:+"$filter"} | rg "=$finder"
    else
      alias | grep -E ${filter:+"$filter"} | grep -E "=$finder"
    fi

    [[ "$exact" == true || "$longer" == true ]] && break
    
    cmd=$(echo "$cmd" | sed -E 's/ {0,}[^ ]*$//')
  done
}

# Automatic execution before each command (optional)
# Requires bash-preexec: https://github.com/rcaloras/bash-preexec
alias-finder-preexec() {
  [[ "${ALIAS_FINDER_AUTOMATIC:-false}" == "true" ]] && alias-finder "$1"
}

# Register with bash-preexec if it's loaded
if [[ "${ALIAS_FINDER_AUTOMATIC:-false}" == "true" ]]; then
  if declare -p preexec_functions &>/dev/null; then
    preexec_functions+=(alias-finder-preexec)
  else
    echo "Warning: ALIAS_FINDER_AUTOMATIC is enabled but bash-preexec is not loaded."
    echo "Please source bash-preexec.sh before this script."
  fi
fi
