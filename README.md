# alias-finder

A modern, well-tested Bash utility that helps you discover and remember shell aliases for commands you type.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)

## Features

- 🔍 **Smart Search**: Finds aliases by exact or partial command matching
- 🚀 **Fast**: Uses ripgrep when available, falls back to grep
- 🎯 **Flexible**: Supports exact, longer, and shorter alias matching modes
- 🔄 **Automatic Suggestions**: Optional integration with bash-preexec for automatic alias suggestions
- 📝 **Well Documented**: Comprehensive help text and examples
- ✅ **Well Tested**: Includes comprehensive test suite
- 🛡️ **Best Practices**: Follows modern Bash scripting best practices

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/alias-finder.git
cd alias-finder

# Install (system-wide, requires sudo)
sudo make install

# Or install to your home directory (no sudo required)
make install-user

# Add to your ~/.bashrc or ~/.bash_profile
echo 'source ~/.local/bin/alias-finder' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Basic Usage

```bash
# Find aliases for a command
alias-finder git status

# Find exact matches only
alias-finder --exact "git commit -m"

# Find only shorter aliases
alias-finder --cheaper "git log --oneline --graph"

# Show help
alias-finder --help
```

### Examples

Assuming you have these aliases defined:

```bash
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log'
alias glo='git log --oneline'
```

Running `alias-finder git status` will output:
```
gs='git status'
```

Running `alias-finder git` will output:
```
gs='git status'
gc='git commit'
gp='git push'
gl='git log'
glo='git log --oneline'
```

Running `alias-finder --exact "git status"` will output only:
```
gs='git status'
```

### Command-Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--exact` | `-e` | Show only exact matches (no partial matches) |
| `--longer` | `-l` | Show aliases that are longer than the command |
| `--cheaper` | `-c` | Show only aliases shorter than the command |
| `--help` | `-h` | Display help message |

### Environment Variables

You can configure alias-finder using environment variables in your `.bashrc`:

```bash
# Show only exact matches by default
export ALIAS_FINDER_EXACT=true

# Show longer aliases by default
export ALIAS_FINDER_LONGER=true

# Show only shorter aliases by default
export ALIAS_FINDER_CHEAPER=true

# Enable automatic suggestions (requires bash-preexec)
export ALIAS_FINDER_AUTOMATIC=true
```

### Automatic Suggestions

For automatic alias suggestions before each command, you need to install [bash-preexec](https://github.com/rcaloras/bash-preexec):

1. Download bash-preexec:
```bash
curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o ~/.bash-preexec.sh
```

2. Add to your `.bashrc`:
```bash
# Load bash-preexec first
source ~/.bash-preexec.sh

# Enable automatic suggestions
export ALIAS_FINDER_AUTOMATIC=true

# Load alias-finder
source ~/.local/bin/alias-finder
```

3. Reload your shell:
```bash
source ~/.bashrc
```

Now whenever you type a command that has an alias, alias-finder will suggest it automatically!

## Installation

### Using Make (Recommended)

```bash
# Install system-wide (requires sudo)
sudo make install

# Install to user directory (no sudo required)
make install-user

# Uninstall
sudo make uninstall
# or
make uninstall-user
```

### Manual Installation

```bash
# Copy the script to a directory in your PATH
cp alias-finder.sh ~/.local/bin/alias-finder
chmod +x ~/.local/bin/alias-finder

# Add to your shell configuration
echo 'source ~/.local/bin/alias-finder' >> ~/.bashrc
source ~/.bashrc
```

## Development

### Running Tests

```bash
# Run the test suite
make test

# Or run directly
bash test.sh
```

### Running Linter

```bash
# Run shellcheck (if installed)
make lint
```

### Running All Checks

```bash
# Run both lint and test
make check
```

### Quick Demo

```bash
# See a quick demonstration
make demo
```

## Requirements

### Required
- Bash 4.0 or later
- Standard Unix utilities: `grep`, `sed`, `tr`

### Optional
- `ripgrep` (rg) - For faster searching (highly recommended)
- `bash-preexec` - For automatic alias suggestions
- `shellcheck` - For development/linting

### Installing Optional Dependencies

```bash
# Check and get installation instructions
make install-deps

# Install ripgrep
# Debian/Ubuntu:
sudo apt-get install ripgrep

# macOS:
brew install ripgrep

# Fedora:
sudo dnf install ripgrep
```

## How It Works

1. **Command Parsing**: The script parses command-line arguments and environment variables
2. **Regex Escaping**: Special characters in the command are escaped for safe regex matching
3. **Alias Search**: Uses `alias` command output and searches with grep/ripgrep
4. **Iterative Matching**: If no exact match is found, progressively removes words from the end
5. **Result Filtering**: Applies filters based on options (exact, longer, cheaper)

## Best Practices

This project follows modern Bash best practices:

- ✅ Proper error handling and input validation
- ✅ Comprehensive documentation (Google Shell Style Guide format)
- ✅ All variables properly quoted and scoped
- ✅ Functions for modularity and testability
- ✅ Shellcheck compliant (when possible)
- ✅ Help text and usage examples
- ✅ Comprehensive test suite
- ✅ Prevention of multiple sourcing
- ✅ Safe handling of special characters

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass: `make check`
5. Follow the existing code style
6. Submit a pull request

## Troubleshooting

### alias-finder: command not found

Make sure the script is in your PATH and you've sourced it:
```bash
source ~/.local/bin/alias-finder
```

### No aliases found

Make sure you have aliases defined. Check with:
```bash
alias
```

### bash-preexec warning

If you see a warning about bash-preexec not being loaded:
1. Install bash-preexec first (see Automatic Suggestions section)
2. Source bash-preexec before alias-finder in your .bashrc
3. Or disable automatic mode: `export ALIAS_FINDER_AUTOMATIC=false`

## License

MIT License - see LICENSE file for details

## Author

alias-finder contributors

## Acknowledgments

- Inspired by the zsh plugin of the same name
- Uses [bash-preexec](https://github.com/rcaloras/bash-preexec) for automatic suggestions
- Uses [ripgrep](https://github.com/BurntSushi/ripgrep) for fast searching

## See Also

- [bash-preexec](https://github.com/rcaloras/bash-preexec) - Preexec hook for Bash
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast grep alternative
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
