#!/bin/bash

# Configuration
LOG_DIR="${LOG_DIR:-../logs}"
LOG_FILE="$LOG_DIR/audit.log"

# Create log directory if it doesn't exist
if ! mkdir -p "$LOG_DIR"; then
    echo "Error: Could not create log directory at $LOG_DIR" >&2
    exit 1
fi

# Get current timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Append log entry
log_entry() {
    local level="$1"
    local username="$2"
    local action="$3"

    # Validate inputs
    if [[ -z "$level" || -z "$action" ]]; then
        echo "Usage: $0 [level] [username] <action>" >&2
        exit 1
    fi

    # Format log entry
    if [ -n "$username" ]; then
        echo "$TIMESTAMP [$level] User $username: $action" >> "$LOG_FILE"
    else
        echo "$TIMESTAMP [$level] $action" >> "$LOG_FILE"
    fi
}

# Call the function
log_entry "$@"

