#!/bin/bash

# Check if log directory exists
LOG_DIR="../logs"
LOG_FILE="$LOG_DIR/audit.log"

mkdir -p "$LOG_DIR"

# Get current timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Append log entry
if [ -n "$1" ]; then
	if [ -n "$2" ]; then
		echo "$TIMESTAMP: User $1: $2" >> "$LOG_FILE"
	else
		echo "$TIMESTAMP: $1" >> "$LOG_FILE"
	fi
else
  echo "Usage: $0 [username] <action>"
fi
