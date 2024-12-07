#!/bin/bash

# Check for username input
if [ -z "$1" ]; then
  echo "Usage: $0 <username>"
  ./audit_log.sh "ERROR" "SSH Setup" "No username provided"
  exit 1
fi

USERNAME=$1
USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

printf "\n\n----- Generating and Configuring SSH Key -----\n\n"

# Create .ssh directory and set permissions
mkdir -p "$SSH_DIR" || { 
    printf "\nError: Could not create .ssh directory.\n\n"; 
    ./audit_log.sh "ERROR" "SSH Setup" "Failed to create .ssh directory for $USERNAME"
    exit 1; 
}
chmod 700 "$SSH_DIR"
chown "$USERNAME:$USERNAME" "$SSH_DIR"

./audit_log.sh "INFO" "SSH Setup" ".ssh directory created for $USERNAME"

# Check if authorized_keys already exists
if [ -f "$AUTH_KEYS" ]; then
    echo "Warning: An existing authorized_keys file was found for user '$USERNAME'."
    ./audit_log.sh "WARNING" "SSH Setup" "authorized_keys file exists for $USERNAME"
    read -p "Do you want to back up and overwrite this file? (Y/N): " choice
    if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
        mv "$AUTH_KEYS" "${AUTH_KEYS}.bak_$(date +%F_%T)"
        printf "\nExisting authorized_keys backed up.\n\n"
        ./audit_log.sh "INFO" "SSH Setup" "Backed up existing authorized_keys for $USERNAME"
    else
        echo "Action canceled. No changes made to authorized_keys."
        ./audit_log.sh "INFO" "SSH Setup" "No changes made to authorized_keys for $USERNAME"
        exit 0
    fi
fi

# Generate SSH key pair
ssh-keygen -f "$SSH_DIR/id_rsa" -t rsa -b 2048 -C "$USERNAME@$(hostname)" -N "" || { 
    echo "Error: SSH key generation failed.";
    ./audit_log.sh "ERROR" "SSH Setup" "Failed to generate SSH key for $USERNAME"
    exit 1; 
}
chown "$USERNAME:$USERNAME" "$SSH_DIR/id_rsa" "$SSH_DIR/id_rsa.pub"

./audit_log.sh "INFO" "SSH Setup" "SSH keys generated for $USERNAME"

# Configure authorized_keys
cat "$SSH_DIR/id_rsa.pub" > "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown "$USERNAME:$USERNAME" "$AUTH_KEYS"

./audit_log.sh "INFO" "SSH Setup" "authorized_keys configured for $USERNAME"

# Log actions
printf "\n\nPrivate key stored at: $SSH_DIR/id_rsa\n"
printf "Public key stored at: $SSH_DIR/id_rsa.pub\n"
printf "SSH setup for user '$USERNAME' completed.\n"

./audit_log.sh "INFO" "SSH Setup" "SSH setup completed for $USERNAME"

