#!/usr/bin/env bash

# ANSI color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# Print welcome banner
echo -e "${CYAN}${BOLD}"
echo -e "════════════════════════════════════════════════════════════════"
echo -e "  WELCOME TO CLOUD CONNEXA PYTHON CLIENT"
echo -e "════════════════════════════════════════════════════════════════${RESET}"
echo
echo -e "${YELLOW}This script will help you set up and test the Cloud Connexa Python client.${RESET}"
echo

# Function to check if make is installed
check_make() {
  if ! command -v make &> /dev/null; then
    echo -e "${RED}${BOLD}Error: 'make' is not installed on your system.${RESET}"
    echo -e "${YELLOW}Please install make first:${RESET}"
    
    if command -v apt-get &> /dev/null; then
      echo -e "  ${CYAN}sudo apt-get install make${RESET}"
    elif command -v yum &> /dev/null; then
      echo -e "  ${CYAN}sudo yum install make${RESET}"
    elif command -v brew &> /dev/null; then
      echo -e "  ${CYAN}brew install make${RESET}"
    else
      echo -e "  ${CYAN}Please install make using your system's package manager.${RESET}"
    fi
    
    exit 1
  fi
}

# Function to run a step with error handling
run_step() {
  local step_num=$1
  local step_name=$2
  local command=$3
  
  echo -e "${BLUE}${BOLD}[STEP ${step_num}/4] ${step_name}...${RESET}"
  if eval "$command"; then
    echo -e "${GREEN}✓ ${step_name} completed successfully${RESET}"
    echo
    return 0
  else
    echo
    echo -e "${RED}${BOLD}╔═════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}${BOLD}║                  ERROR DURING ${step_name^^}                  ║${RESET}"
    echo -e "${RED}${BOLD}╚═════════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${YELLOW}Setup aborted due to errors.${RESET}"
    exit 1
  fi
}

# Step 1: Check prerequisites
run_step "1" "Checking prerequisites" "check_make && echo -e \"${GREEN}✓ Make is installed${RESET}\""

# Step 2: Setup environment
run_step "2" "Setting up development environment" "make setup"

# Step 3: Run tests
run_step "3" "Running tests to verify installation" "make test"

# Step 4: Next steps
echo -e "${BLUE}${BOLD}[STEP 4/4] Setup complete!${RESET}"
echo
echo -e "${GREEN}${BOLD}What's next?${RESET}"
echo -e "${CYAN}1. Read the documentation in README.md${RESET}"
echo -e "${CYAN}2. Explore example code in docs/examples/${RESET}"
echo -e "${CYAN}3. Set up your API credentials${RESET}"
echo
echo -e "${YELLOW}Example usage:${RESET}"
echo -e "${CYAN}from cloudconnexa import CloudConnexaClient

client = CloudConnexaClient(
    api_url=\"https://your-cloud-id.api.openvpn.com\",
    client_id=\"your-client-id\",
    client_secret=\"your-client-secret\"
)

# List all networks
networks = client.networks.list()
print(f\"Found {len(networks)} networks\")${RESET}"
echo
echo -e "${GREEN}${BOLD}Happy coding! 🚀${RESET}"
echo 