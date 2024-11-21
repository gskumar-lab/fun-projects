#!/bin/bash

# Ensure the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[0;31mThis script must be run as root!\033[0m"
    exit 1
fi

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Function to display the menu
display_menu() {
    echo -e "${CYAN}==================== User Management ===================="
    echo "1. Add a new user"
    echo "2. Delete a user"
    echo "3. List all users"
    echo "4. Lock a user account"
    echo "5. Unlock a user account"
    echo "6. Change user password"
    echo "7. Exit"
    echo "========================================================${RESET}"
}

# Function to add a new user
add_user() {
    read -p "Enter the username to add: " username
    if [[ ! "$username" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo -e "${RED}Invalid username! Usernames can only contain letters, numbers, dots, hyphens, and underscores.${RESET}"
        return
    fi
    if id "$username" &>/dev/null; then
        echo -e "${RED}User '$username' already exists!${RESET}"
    else
        sudo useradd -m "$username" && echo -e "${GREEN}User '$username' added successfully.${RESET}"
        read -p "Set password for $username? (y/n): " set_password
        if [[ "$set_password" == "y" ]]; then
            sudo passwd "$username"
        fi
    fi
}

# Function to delete a user
delete_user() {
    read -p "Enter the username to delete: " username
    if id "$username" &>/dev/null; then
        read -p "Are you sure you want to delete '$username'? This action cannot be undone. (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            sudo userdel -r "$username" && echo -e "${GREEN}User '$username' deleted successfully.${RESET}"
        else
            echo -e "${CYAN}Action canceled.${RESET}"
        fi
    else
        echo -e "${RED}User '$username' does not exist!${RESET}"
    fi
}

# Function to list all users
list_users() {
    echo -e "${CYAN}Listing all users:${RESET}"
    awk -F: '{ print $1 }' /etc/passwd
}

# Function to lock a user account
lock_user() {
    read -p "Enter the username to lock: " username
    if id "$username" &>/dev/null; then
        sudo usermod -L "$username" && echo -e "${GREEN}User '$username' locked successfully.${RESET}"
    else
        echo -e "${RED}User '$username' does not exist!${RESET}"
    fi
}

# Function to unlock a user account
unlock_user() {
    read -p "Enter the username to unlock: " username
    if id "$username" &>/dev/null; then
        sudo usermod -U "$username" && echo -e "${GREEN}User '$username' unlocked successfully.${RESET}"
    else
        echo -e "${RED}User '$username' does not exist!${RESET}"
    fi
}

# Function to change user password
change_password() {
    read -p "Enter the username to change password: " username
    if id "$username" &>/dev/null; then
        sudo passwd "$username"
    else
        echo -e "${RED}User '$username' does not exist!${RESET}"
    fi
}

# Main loop
while true; do
    display_menu
    read -p "Choose an option [1-7]: " choice
    case $choice in
        1) add_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) lock_user ;;
        5) unlock_user ;;
        6) change_password ;;
        7) echo -e "${CYAN}Exiting...${RESET}"; exit 0 ;;
        *) echo -e "${RED}Invalid option! Please try again.${RESET}" ;;
    esac
    echo
done

