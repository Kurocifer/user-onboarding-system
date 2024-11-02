#!/bin/bash

# Check for username input
if [ -z "$1" ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

USERNAME=$1
USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"


printf "\n\n----- Generating and Configuring SSH Key -----\n\n"
# Create .ssh directory and set permissions
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$USERNAME:$USERNAME" "$SSH_DIR"


# Generate SSH key pair
ssh-keygen -f "$SSH_DIR/id_rsa" -t rsa -b 2048 -C "$USERNAME@$(hostname)" -N ""
chown "$USERNAME:$USERNAME" "$SSH_DIR/id_rsa" "$SSH_DIR/id_rsa.pub"
cat "$SSH_DIR/id_rsa.pub" > "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown "$USERNAME:$USERNAME" "$AUTH_KEYS"


printf "\nSSH key generated and configured for $USERNAME.\n"
./audit_log.sh "$USERNAME" "SSH Setup"

