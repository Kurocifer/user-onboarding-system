#!/bin/bash

# Load permissions
source ../config/permissions.sh

print_permissions() {
	echo "0 - Default Permmissions: "$DEFAULT_PERMISSIONS""
	echo "1 - Private Access: "$PRIVATE_ACCESS""
	echo "2 - Group Collaboration: "$GROUP_COLLABORATION""
	echo "3 - Full Group Access: "$FULL_GROUP_ACCESS""
	echo "4 - Open Access: "$OPEN_ACCESS""
	echo "5 - Read Only Files: "$READ_ONLY_FILES""
	echo "6 - Private Files: "$PRIVATE_FILES""
}


LIST_OF_USER_PERMISSIONS=("$DEFAULT_PERMISSIONS" "$PRIVATE_ACCESS" "$GROUP_COLLABORATION" "$FULL_GROUP_ACCESS" "$OPEN_ACCESS" "$READ_ONLY_FILES" "$PRIVATE_FILES")


# Check if script is granted root access
if [[ $EUID -ne 0 ]]; then
	printf "\nThis script requires root access\n"
	echo "Try running: sudo $0"
	exit 1
fi


# Check if username is provided as command line arguement
if [ -z "$1" ]; then
	printf "\nUsage: $0 <username>\n"
	exit 1
fi

USERNAME=$1
USER_HOME="/home/$USERNAME"


printf "\n\n----- Setting up New User Onboarding -----\n\n"

# Crete user and set their default shell to bash
useradd -m -d "$USER_HOME" -s /bin/bash "$USERNAME"
printf "\nUser $USERNAME created successfully.\n"



# Set user permissions
printf "\nSelect from the list below the permissions to be assigned to the user (0 - 6)\n\n"
print_permissions
read -p "choice: " choice

# check if choice is valid
if [[ "$choice" -gt 6 || "$choice" -lt 0 ]]; then
	printf "\nInvalid entry. Your choce should be between 0 - 6\n"
	exit 1
fi

USER_PERMISSIONS=${LIST_OF_USER_PERMISSIONS[choice]}
chmod "$USER_PERMISSIONS" "$USER_HOME"
printf "\nPermissions "$USER_PERMISSIONS" have been set for $USER_HOME.\n"


# Add user to groups
usermod -aG sudo "$USERNAME" # Add to sudo group
printf "\n$USERNAME added to default groups.\n"


# Run ssh setup script
./setup_ssh.sh "$USERNAME"
