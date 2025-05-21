.PHONY: setup test clean dev lint install shell check-venv check-python check-venv-module install-system-deps

# Detect Python command (try python3 first, then python)
PYTHON_CMD := $(shell command -v python3 2> /dev/null || command -v python 2> /dev/null)

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	IS_DEBIAN := $(shell command -v apt-get > /dev/null && echo "1" || echo "0")
endif

# Virtual environment settings
VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/pytest
FLAKE8 := $(VENV)/bin/flake8
MYPY := $(VENV)/bin/mypy

# Allow passing arguments to pytest
PYTEST_ARGS ?= tests/ -v

# ANSI color codes
CYAN := "\033[36m"
GREEN := "\033[32m"
YELLOW := "\033[33m"
BOLD := "\033[1m"
RESET := "\033[0m"
RED := "\033[31m"

# Default target
all: setup test

# Check if Python is installed
check-python:
	@if [ -z "$(PYTHON_CMD)" ]; then \
		echo; \
		echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET); \
		echo $(CYAN)$(BOLD)"  PYTHON CHECK FAILED"$(RESET); \
		echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET); \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ Error: Neither python3 nor python was found."$(RESET); \
		echo $(RED)"  ✗ Please install Python 3 before continuing."$(RESET); \
		echo; \
		exit 1; \
	fi
	@echo $(GREEN)"✓ Using Python: $(PYTHON_CMD)"$(RESET)

# Check if venv module is available
check-venv-module:
	@echo $(YELLOW)"► Checking for Python venv module..."$(RESET)
	@if ! $(PYTHON_CMD) -c "import ensurepip" 2>/dev/null; then \
		echo; \
		echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET); \
		echo $(CYAN)$(BOLD)"  VENV MODULE CHECK FAILED"$(RESET); \
		echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET); \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ The Python venv module is not available."$(RESET); \
		if [ "$(IS_DEBIAN)" = "1" ]; then \
			echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
			echo $(YELLOW)"On Debian/Ubuntu systems, you need to install the python3-venv package:"$(RESET); \
			echo $(CYAN)"    sudo apt install python3-venv"$(RESET); \
			echo; \
			read -p "$(BOLD)Would you like the Makefile to attempt installing it now? (y/n)$(RESET) " answer; \
			if [ "$$answer" = "y" ]; then \
				echo; \
				echo $(YELLOW)$(BOLD)"▶ Installing python3-venv..."$(RESET); \
				echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
				sudo apt install -y python3-venv; \
				echo $(GREEN)"✓ python3-venv installed successfully"$(RESET); \
			else \
				echo; \
				echo $(YELLOW)"Please install the required package and run 'make setup' again."$(RESET); \
				exit 1; \
			fi; \
		else \
			echo $(YELLOW)"Please install the Python venv module for your system and try again."$(RESET); \
			exit 1; \
		fi; \
	fi

# Install system dependencies
install-system-deps:
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  INSTALLING SYSTEM DEPENDENCIES"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ Checking for system dependencies..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@if [ "$(IS_DEBIAN)" = "1" ]; then \
		if ! dpkg -l python3-venv >/dev/null 2>&1; then \
			echo $(YELLOW)$(BOLD)"▶ Installing python3-venv..."$(RESET); \
			echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
			sudo apt install -y python3-venv; \
			echo $(GREEN)"  ✓ python3-venv installed successfully"$(RESET); \
		else \
			echo $(GREEN)"  ✓ python3-venv is already installed"$(RESET); \
		fi; \
		echo; \
		echo $(GREEN)$(BOLD)"✅ All system dependencies are installed!"$(RESET); \
		echo $(GREEN)$(BOLD)"────────────────────────────────────────────────────────────"$(RESET); \
	else \
		echo $(YELLOW)"  Non-Debian system detected. Please install Python venv module manually."$(RESET); \
		echo; \
	fi
	@echo

# Check if virtual environment exists
check-venv:
	@if [ ! -d $(VENV) ]; then \
		echo; \
		echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET); \
		echo $(CYAN)$(BOLD)"  VIRTUAL ENVIRONMENT CHECK FAILED"$(RESET); \
		echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET); \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ Error: Virtual environment not found."$(RESET); \
		echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
		echo $(YELLOW)"Please run 'make setup' first to create the virtual environment."$(RESET); \
		echo; \
		exit 1; \
	fi

# Set up development environment
setup: check-python check-venv-module
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  SETTING UP DEVELOPMENT ENVIRONMENT"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@if [ -d "$(VENV)" ]; then \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ Virtual environment already exists. Updating dependencies..."$(RESET); \
		echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ Upgrading pip, setuptools, and wheel..."$(RESET); \
		echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
		$(PIP) install --upgrade pip setuptools wheel; \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ Updating project dependencies..."$(RESET); \
		echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
		$(PIP) install -e ".[dev]"; \
		$(PIP) install -r requirements.txt; \
		echo; \
		echo $(GREEN)$(BOLD)"✅ Virtual environment has been updated successfully!"$(RESET); \
		echo $(GREEN)$(BOLD)"────────────────────────────────────────────────────────────"$(RESET); \
		echo; \
	else \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ Creating new virtual environment..."$(RESET); \
		echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
		$(PYTHON_CMD) -m venv $(VENV); \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ Installing pip, setuptools, and wheel..."$(RESET); \
		echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
		$(PIP) install --upgrade pip setuptools wheel; \
		echo; \
		echo $(YELLOW)$(BOLD)"▶ Installing project dependencies..."$(RESET); \
		echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET); \
		$(PIP) install -e ".[dev]"; \
		$(PIP) install -r requirements.txt; \
		echo; \
		echo $(GREEN)$(BOLD)"✅ Virtual environment is set up successfully! You can now use make commands without activation!"$(RESET); \
		echo $(GREEN)$(BOLD)"────────────────────────────────────────────────────────────"$(RESET); \
		echo; \
	fi

# Run tests
test: check-venv
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  RUNNING TESTS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ Executing pytest with arguments: $(PYTEST_ARGS)"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@$(PYTEST) $(PYTEST_ARGS)
	@echo
	@echo $(GREEN)$(BOLD)"✅ Testing completed!"$(RESET)
	@echo $(GREEN)$(BOLD)"────────────────────────────────────────────────────────────"$(RESET)
	@echo

# Clean up build artifacts and cache
clean:
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  CLEANING PROJECT ENVIRONMENT"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	
	@echo $(YELLOW)$(BOLD)"▶ Removing build artifacts and directories..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@rm -rf build/ dist/ *.egg-info/ .pytest_cache/ .coverage htmlcov/
	@echo "  ✓ Removed build/, dist/, *.egg-info/, .pytest_cache/, .coverage, htmlcov/"
	
	@echo
	@echo $(YELLOW)$(BOLD)"▶ Removing Python cache files..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@echo "  ✓ Removed all __pycache__ directories"
	
	@echo
	@echo $(YELLOW)$(BOLD)"▶ Removing egg-info directories..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@echo "  ✓ Removed all *.egg-info directories"
	
	@echo
	@echo $(GREEN)$(BOLD)"✅ Cleanup completed successfully!"$(RESET)
	@echo $(GREEN)$(BOLD)"────────────────────────────────────────────────────────────"$(RESET)
	@echo

# Run development server or main application
dev: check-venv
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  STARTING DEVELOPMENT SERVER"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ Running main application..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@$(PYTHON) -m src.main

# Run linting
lint: check-venv
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  LINTING CODE"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	
	@echo $(YELLOW)$(BOLD)"▶ Running flake8..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@$(FLAKE8) src/ tests/ || (echo "Flake8 found issues"; exit 1)
	@echo "  ✓ Flake8 checks passed"
	
	@echo
	@echo $(YELLOW)$(BOLD)"▶ Running mypy type checking..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@$(MYPY) src/ tests/ || (echo "Mypy found issues"; exit 1)
	@echo "  ✓ Mypy checks passed"
	
	@echo
	@echo $(GREEN)$(BOLD)"✅ All linting checks passed successfully!"$(RESET)
	@echo $(GREEN)$(BOLD)"────────────────────────────────────────────────────────────"$(RESET)
	@echo

# Install in development mode
install: check-venv
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  INSTALLING PACKAGE IN DEVELOPMENT MODE"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ Installing package..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@$(PIP) install -e .
	@echo
	@echo $(GREEN)$(BOLD)"✅ Package installed successfully in development mode!"$(RESET)
	@echo $(GREEN)$(BOLD)"────────────────────────────────────────────────────────────"$(RESET)
	@echo

# Create a shell with the virtual environment activated
shell: check-venv
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  ACTIVATING VIRTUAL ENVIRONMENT SHELL"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ Starting a new shell with the virtual environment activated..."$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)$(BOLD)"✓ When you're done, type 'exit' to return to your original shell."$(RESET)
	@echo
	@exec $(SHELL) -c "source $(VENV)/bin/activate && $(SHELL)"

# Help command
help:
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo $(CYAN)$(BOLD)"  OVPN CONNEXA PYTHON CLIENT - MAKE COMMANDS"$(RESET)
	@echo $(CYAN)$(BOLD)"════════════════════════════════════════════════════════════════"$(RESET)
	@echo
	@echo $(YELLOW)$(BOLD)"▶ SETUP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make setup               "$(RESET)" - Create virtual environment and install dependencies"
	@echo $(GREEN)"  make install-system-deps "$(RESET)" - Install required system dependencies (needs sudo)"
	@echo $(GREEN)"  make install             "$(RESET)" - Install package in development mode"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ DEVELOPMENT COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make dev                 "$(RESET)" - Run development server/application"
	@echo $(GREEN)"  make shell               "$(RESET)" - Start a shell with the virtual environment activated"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ TESTING & QUALITY COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make test                "$(RESET)" - Run all tests with pytest"
	@echo $(GREEN)"  make PYTEST_ARGS=\"path/to/test.py -v\" test"$(RESET)" - Run specific tests with custom arguments"
	@echo $(GREEN)"  make lint                "$(RESET)" - Run linters (flake8, mypy)"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ MAINTENANCE COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make clean               "$(RESET)" - Remove build artifacts and cache"
	@echo
	@echo $(YELLOW)$(BOLD)"▶ HELP COMMANDS:"$(RESET)
	@echo $(YELLOW)"────────────────────────────────────────────────────────────"$(RESET)
	@echo $(GREEN)"  make help                "$(RESET)" - Show this help message"
	@echo
	@echo "Available commands:"
	@echo "  make setup                 - Create virtual environment and install dependencies"
	@echo "  make install-system-deps   - Install required system dependencies (needs sudo)"
	@echo "  make test                  - Run all tests with pytest"
	@echo "  make PYTEST_ARGS=\"path/to/test.py -v\" test - Run specific tests with custom arguments"
	@echo "  make clean                 - Remove build artifacts and cache"
	@echo "  make dev                   - Run development server/application"
	@echo "  make lint                  - Run linters (flake8, mypy)"
	@echo "  make install               - Install package in development mode"
	@echo "  make shell                 - Start a shell with the virtual environment activated"
	@echo "  make help                  - Show this help message" 