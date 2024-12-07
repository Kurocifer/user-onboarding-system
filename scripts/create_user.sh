#!/bin/bash

# Load permissions
source ../config/permissions.sh || {
    printf "\nError: Unable to load permissions configuration. Exiting.\n"
    exit 1
}

print_permissions() {
    printf "0 - Default Permissions: %s\n" "$DEFAULT_PERMISSIONS"
    printf "1 - Private Access: %s\n" "$PRIVATE_ACCESS"
    printf "2 - Group Collaboration: %s\n" "$GROUP_COLLABORATION"
    printf "3 - Full Group Access: %s\n" "$FULL_GROUP_ACCESS"
    printf "4 - Open Access: %s\n" "$OPEN_ACCESS"
    printf "5 - Read Only Files: %s\n" "$READ_ONLY_FILES"
    printf "6 - Private Files: %s\n" "$PRIVATE_FILES"
}

group_exist() {
    getent group "$1" > /dev/null 2>&1
}

create_group() {
    groupadd "$1" && printf "Group '%s' created successfully.\n" "$1"
}

add_user_to_group() {
    usermod -aG "$1" "$2" && printf "User '%s' successfully added to group '%s'.\n" "$2" "$1"
}

setup_user() {
    local username="$1"
    local user_home="/home/$username"

    # Create user and set their default shell to bash
    if useradd -m -d "$user_home" -s /bin/bash "$username"; then
        printf "\nUser '%s' created successfully.\n\n" "$username"
		./audit_log.sh INFO "$username" "User created."
    else
        printf "\nError: Failed to create user '%s'. Exiting.\n" "$username"
		./audit_log.sh ERROR "$username" "Failed to create user."
        exit 1
    fi

    # Set user permissions
    printf "\nSelect from the list below the permissions to be assigned to the user (0 - 6):\n\n"
    print_permissions
    read -p "Choice: " choice

    # Check if choice is valid
    if [[ "$choice" -gt 6 || "$choice" -lt 0 ]]; then
        printf "\nInvalid entry. Your choice should be between 0 - 6.\n"
		./audit_log.sh WARNING "$username" "Invalid permission choice."
        exit 1
    fi

    USER_PERMISSIONS=${LIST_OF_USER_PERMISSIONS[$choice]}
    chmod "$USER_PERMISSIONS" "$user_home" && \
        printf "\nPermissions '%s' have been set for %s.\n\n" "$USER_PERMISSIONS" "$user_home"
	./audit_log.sh INFO "$username" "Permissions '$USER_PERMISSIONS' set for home directory."
}

set_password() {
    local username="$1"
    read -p "Do you want to set a password for this user? (Y/N): " choice

    if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
        passwd "$username" && \
            printf "\nPassword for user '%s' set successfully.\n\n" "$username"
		./audit_log.sh INFO "$username" "Password set."
    fi
}

add_user_to_groups() {
    local username="$1"

    read -p "Do you want to add this user to groups? (Y/N): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        while true; do
            read -p "Group name: " group_name

            if group_exist "$group_name"; then
                add_user_to_group "$group_name" "$username"
            else
                read -p "'$group_name' does not exist. Create it? (Y/N): " create_group_prompt
                if [[ "$create_group_prompt" == "y" || "$create_group_prompt" == "Y" ]]; then
                    create_group "$group_name"
                    add_user_to_group "$group_name" "$username"
                fi
            fi

            read -p "Add user to another group? (Y/N): " choice
            if [[ "$choice" != "Y" && "$choice" != "y" ]]; then
                break
            fi
        done
        printf "Note: User will need to log out and back in for group changes to take effect.\n\n"
    fi
}

# Check if script is granted root access
if [[ $EUID -ne 0 ]]; then
    printf "\nThis script requires root access.\n"
    printf "Try running: sudo %s\n" "$0"
	./audit_log.sh ERROR "System" "Root access required."
    exit 1
fi

# Check if username is provided as command line argument
if [ -z "$1" ]; then
    printf "\nUsage: %s <username>\n" "$0"
	./audit_log.sh WARNING "System" "No username provided."
    exit 1
fi

USERNAME=$1
LIST_OF_USER_PERMISSIONS=("$DEFAULT_PERMISSIONS" "$PRIVATE_ACCESS" "$GROUP_COLLABORATION" "$FULL_GROUP_ACCESS" "$OPEN_ACCESS" "$READ_ONLY_FILES" "$PRIVATE_FILES")

printf "\n\n----- Setting up New User Onboarding -----\n\n"

setup_user "$USERNAME"
set_password "$USERNAME"
add_user_to_groups "$USERNAME"

# Run ssh setup script
if ./setup_ssh.sh "$USERNAME"; then
    printf "\nSSH setup completed for user '%s'.\n\n" "$USERNAME"
else
    printf "\nWarning: SSH setup failed for user '%s'.\n\n" "$USERNAME"
fi

./audit_log.sh INFO "$USERNAME" "Onboarding completed."
printf "User Onboarding for '%s' completed.\n" "$USERNAME"

