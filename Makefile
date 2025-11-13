.PHONY: help install uninstall test lint clean check

# Default target
.DEFAULT_GOAL := help

# Installation directory
PREFIX ?= /usr/local
INSTALL_DIR = $(PREFIX)/bin
SCRIPT_NAME = alias-finder.sh

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help message
	@printf "$(BLUE)alias-finder - Makefile Commands$(NC)\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@printf "\n$(YELLOW)Environment Variables:$(NC)\n"
	@printf "  PREFIX          Installation prefix (default: /usr/local)\n"
	@printf "  INSTALL_DIR     Installation directory (default: \$$PREFIX/bin)\n"

test: ## Run the test suite
	@printf "$(BLUE)Running tests...$(NC)\n"
	@env -u ALIAS_FINDER_AUTOMATIC -u ALIAS_FINDER_CHEAPER -u ALIAS_FINDER_EXACT -u ALIAS_FINDER_LONGER bash test.sh

lint: ## Run shellcheck on the script (if available)
	@printf "$(BLUE)Running shellcheck...$(NC)\n"
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck $(SCRIPT_NAME) test.sh; \
		printf "$(GREEN)✓ Shellcheck passed$(NC)\n"; \
	else \
		printf "$(YELLOW)⚠ shellcheck not found, skipping lint$(NC)\n"; \
		printf "  Install with: apt-get install shellcheck (Debian/Ubuntu)\n"; \
		printf "               brew install shellcheck (macOS)\n"; \
	fi

check: lint test ## Run all checks (lint + test)

install: ## Install alias-finder to system
	@printf "$(BLUE)Installing alias-finder to $(INSTALL_DIR)...$(NC)\n"
	@mkdir -p $(INSTALL_DIR)
	@install -m 755 $(SCRIPT_NAME) $(INSTALL_DIR)/alias-finder
	@printf "$(GREEN)✓ Installed successfully$(NC)\n"
	@printf "\nTo use alias-finder:\n"
	@printf "  1. Add to your ~/.bashrc or ~/.bash_profile:\n"
	@printf "     source $(INSTALL_DIR)/alias-finder\n"
	@printf "  2. Reload your shell:\n"
	@printf "     source ~/.bashrc\n"
	@printf "  3. Run:\n"
	@printf "     alias-finder <command>\n"

install-user: ## Install alias-finder to user's home directory
	@printf "$(BLUE)Installing alias-finder to ~/.local/bin...$(NC)\n"
	@mkdir -p ~/.local/bin
	@install -m 755 $(SCRIPT_NAME) ~/.local/bin/alias-finder
	@printf "$(GREEN)✓ Installed successfully$(NC)\n"
	@printf "\nTo use alias-finder:\n"
	@printf "  1. Ensure ~/.local/bin is in your PATH\n"
	@printf "  2. Add to your ~/.bashrc or ~/.bash_profile:\n"
	@printf "     source ~/.local/bin/alias-finder\n"
	@printf "  3. Reload your shell:\n"
	@printf "     source ~/.bashrc\n"

uninstall: ## Uninstall alias-finder from system
	@printf "$(BLUE)Uninstalling alias-finder...$(NC)\n"
	@rm -f $(INSTALL_DIR)/alias-finder
	@printf "$(GREEN)✓ Uninstalled successfully$(NC)\n"

uninstall-user: ## Uninstall alias-finder from user's home directory
	@printf "$(BLUE)Uninstalling alias-finder from ~/.local/bin...$(NC)\n"
	@rm -f ~/.local/bin/alias-finder
	@printf "$(GREEN)✓ Uninstalled successfully$(NC)\n"

clean: ## Remove temporary files
	@printf "$(BLUE)Cleaning up...$(NC)\n"
	@rm -f *~ *.bak
	@printf "$(GREEN)✓ Cleaned$(NC)\n"

demo: ## Run a quick demo
	@printf "$(BLUE)Running alias-finder demo...$(NC)\n"
	@printf "\nSetting up test aliases...\n"
	@bash -c 'source ./$(SCRIPT_NAME); \
		alias gs="git status"; \
		alias gc="git commit"; \
		alias gp="git push"; \
		printf "\nTest 1: Finding aliases for \"git status\":\n"; \
		alias-finder git status || true; \
		printf "\nTest 2: Finding aliases for \"git\" (partial match):\n"; \
		alias-finder git || true; \
		printf "\nTest 3: Help message:\n"; \
		alias-finder --help | head -n 10'

.PHONY: install-deps
install-deps: ## Install optional dependencies (ripgrep)
	@printf "$(BLUE)Checking dependencies...$(NC)\n"
	@if command -v rg >/dev/null 2>&1; then \
		printf "$(GREEN)✓ ripgrep is already installed$(NC)\n"; \
	else \
		printf "$(YELLOW)⚠ ripgrep (rg) is not installed$(NC)\n"; \
		printf "\nripgrep is optional but recommended for better performance.\n"; \
		printf "Install with:\n"; \
		printf "  Debian/Ubuntu: apt-get install ripgrep\n"; \
		printf "  macOS:         brew install ripgrep\n"; \
		printf "  Fedora:        dnf install ripgrep\n"; \
	fi
