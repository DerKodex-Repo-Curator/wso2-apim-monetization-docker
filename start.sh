#!/bin/bash

# alias docker=nerdctl

# Detect TTY and define colors (fallback to empty strings)
if [ -t 1 ]; then
  BOLD="\033[1m"
  RESET="\033[0m"
  RED="\033[1;31m"
  GREEN="\033[1;32m"
  YELLOW="\033[1;33m"
  BLUE="\033[1;34m"
  MAGENTA="\033[1;35m"
else
  BOLD="" RESET="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA=""
fi

### Load the secrets
ENV_FILE="./apim/secrets.env"
if [ -f "$ENV_FILE" ]; then
  printf "✅ Stripe keys already provided; stored at $ENV_FILE\n"
  source $ENV_FILE
else
  echo "$ENV_FILE not found! This must be the first time you are running the script. Please enter the keys you obtained from Stripe, these will be stored and reused on subsequent runs"

  # Prompt for keys
  echo
  printf "${BOLD}${MAGENTA}Enter BillingEnginePlatformAccountKey:${RESET} "
  read BILLING_KEY
  echo
  printf "${BOLD}${MAGENTA}Enter ConnectedAccountKey:${RESET} "
  read CONNECTED_KEY
  echo

  # Prompt for keys
  # read -p "Enter BillingEnginePlatformAccountKey (similar to sk_test_...): " BILLING_KEY
  # read -p "Enter ConnectedAccountKey (similar to acct_...): " CONNECTED_KEY

  # Validate keys 
  if [ -z "$BILLING_KEY" ] || [ -z "$CONNECTED_KEY" ]; then
      echo "ERROR: Both keys must be provided"
      exit 1
  fi

  # Create the .env file
  printf "= Creating $ENV_FILE..."
  {
    echo "BillingEnginePlatformAccountKey=$BILLING_KEY"
    echo "ConnectedAccountKey=$CONNECTED_KEY"
  } > "$ENV_FILE" || { echo "Error: Failed to write to $ENV_FILE. Check permissions"; exit 1; }

  # Set secure permissions
  chmod 600 "$ENV_FILE"
  source $ENV_FILE

  printf "\r✅ Created $ENV_FILE with secure permissions.\n"
fi

ENV_FILE_URLS="./.env"
if [ -f "$ENV_FILE_URLS" ]; then
  source $ENV_FILE_URLS
fi

### Define your cleanup function
cleanup() {
    chmod +x ./stop.sh
    ./stop.sh
}

### Execute clean up and start docker compose
cleanup
docker-compose up -d

chmod +x ./elk/kibana-setup.sh
./elk/kibana-setup.sh

### WSO2 API Manager
TIMEOUT_SECONDS=350
SLEEP_DURATION=0.1
start_time=$(date +%s) # Get the current time in seconds since epoch

spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
i=0
seconds=0
# elapsed_time=0

while [[ $(curl -sk -o /dev/null -w "%{http_code}" https://localhost:8300/pizzashack/1.0.0/menu) != 401 ]]; do
    current_time=$(date +%s)
    seconds=$((current_time - start_time))
    if [ $seconds -ge $TIMEOUT_SECONDS ]; then
        printf "\r❌ ERROR: WSO2 API Manager did not become ready within ${TIMEOUT_SECONDS} seconds\n"
        cleanup
        exit 1 # Exit with a non-zero status (1) to indicate failure/timeout
    fi

    i=$(( (i+1) % ${#spin} ))
    message="${spin:$i:1} WSO2 API Manager with sample PizzaShackAPI"
    timer=$(printf "%5.1fs" "$seconds")
    printf "\r%*s\r%s" $(tput cols) "$timer" "$message";

    sleep $SLEEP_DURATION
    # seconds=$(echo "$seconds + 0.1" | bc)
done
printf "\r✅ WSO2 API Manager with sample PizzaShackAPI\n"

chmod +x ./apim/make-requests.sh
./apim/make-requests.sh

chmod +x ./apim/publish-monetization-data.sh
./apim/publish-monetization-data.sh

# chmod +x ./apim/load-ai-policies.sh
# ./apim/load-ai-policies.sh

### Print final output
# --- Function to print a separator line ---
print_separator() {
  printf '=%.0s' {1..60} # Print 60 '=' characters
  printf '\n'
}

# --- Main Output ---
printf "\n"
printf "${BOLD}${GREEN}=== API Manager Access Information ===${RESET}\n\n"

# Use printf for aligned output. Adjust "-18s" based on the longest label.
printf "  ${BOLD}%-18s${RESET}: ${BLUE}%s${RESET}\n" "Publisher Portal" "https://localhost:9500/publisher/apis"
printf "  ${BOLD}%-18s${RESET}: ${BLUE}%s${RESET}\n" "Developer Portal" "https://localhost:9500/devportal"
printf "  ${BOLD}%-18s${RESET}: ${BLUE}%s${RESET}\n" "Admin Portal"     "https://localhost:9500/admin/dashboard"
printf "\n"
printf "  ${BOLD}%-18s${RESET}: ${MAGENTA}%s${RESET}\n" "Username"         "admin"
printf "  ${BOLD}%-18s${RESET}: ${MAGENTA}%s${RESET}\n" "Password"         "admin"
printf "\n"

printf "${BOLD}${GREEN}=== Kibana Dashboard Access ===${RESET}\n\n"

printf "  ${BOLD}%-18s${RESET}: ${BLUE}%s${RESET}\n" "URL"              "http://localhost:5601/app/dashboards#/view/f954a940-6ed4-11ec-9007-b93f9eb88870"
printf "\n"
printf "  ${BOLD}%-18s${RESET}: ${MAGENTA}%s${RESET}\n" "Username"         "elastic"
printf "  ${BOLD}%-18s${RESET}: ${MAGENTA}%s${RESET}\n" "Password"         "changeme"
printf "\n"
