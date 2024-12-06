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

group_exist() {
	getent group "$1" > /dev/null 2>&1
}

create_group() {
	groupadd "$1"
	echo "Group '$1' created successfully"
}

add_user_to_group() {
	usermod -aG "$1" "$2"
	echo "User '$2" successfully added to group $1"
}

LIST_OF_USER_PERMISSIONS=("$DEFAULT_PERMISSIONS" "$PRIVATE_ACCESS" "$GROUP_COLLABORATION" "$FULL_GROUP_ACCESS" "$OPEN_ACCESS" "$READ_ONLY_FILES" "$PRIVATE_FILES")


# Check if script is granted root access
if [[ $EUID -ne 0 ]]; then
	printf "\nThis script requires root access\n"
	echo "Try running: sudo $0"
	./audit_log.sh "Access Denied"
	exit 1
fi


# Check if username is provided as command line arguement
if [ -z "$1" ]; then
	printf "\nUsage: $0 <username>\n"
	./audit_log.sh "No username provided"
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
	./audit_log.sh "Invalid Permmission selected"
	exit 1
fi

USER_PERMISSIONS=${LIST_OF_USER_PERMISSIONS[choice]}
chmod "$USER_PERMISSIONS" "$USER_HOME"
printf "\nPermissions "$USER_PERMISSIONS" have been set for $USER_HOME.\n"

read -p "Do you want to set a password for this user ? (Y/N): " choice

if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
	passwd $USERNAME
	printf "\n password for user '$USERNAME' set successfully\n"
fi


# Add user to groups
# usermod -aG sudo "$USERNAME" # Add to sudo group
# printf "\n$USERNAME added to default groups.\n"

read -p "Do you want to add this user to groups ? (Y/N): " choice

if [[ "$choice == "y" || "$choice" == "Y" ]]; then
	while True
	do
		read -p "group name: " group_name

		if group_exist $group_name; then
			add_user_to_group $group_name $USERNAME
		else
			read -p "'$group_name' does not exist create it ? (Y/N): " create_group_prompt
		fi
		if [[ "$create_group_prompt" == "y" || "$create_group_prompt" == "Y" ]]; then
			create_group $group_name
			add_user_to_group $group_name $USERNAME

		read -p "add user to another group ? (Y/N): " choice
		if [[ "$choice" != "Y" || "$choice" != "y" ]]; then
			break
	done

# Run ssh setup script
./setup_ssh.sh "$USERNAME"

./audit_log.sh "$USERNAME" "Created"


echo "User Onboarding for $USERNAME completed"
