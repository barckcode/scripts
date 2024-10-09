#!/bin/bash

# Function to display script usage
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -c, --create             Create a new user (requires -n, -u, -p, -k)"
    echo "  -d, --delete             Delete an existing user (requires -u)"
    echo "  -n, --name <name>        Full name of the user (in quotes)"
    echo "  -u, --username <user>    Username for the system"
    echo "  -p, --password <pass>    Temporary password for the user"
    echo "  -k, --key <public_key>   SSH public key (in quotes)"
    echo
    echo "Examples:"
    echo "  Create user: $0 -c -n \"Gandalf the Grey\" -u ggrey -p \"1Temp0r@l\" -k \"ssh-rsa AAAA...\""
    echo "  Delete user: $0 -d -u ggrey"
}

# Function to create a user
create_user() {
    # Check if all required arguments are provided
    if [ -z "$FULL_NAME" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$SSH_KEY" ]; then
        echo "Error: Missing required arguments for user creation."
        show_usage
        exit 1
    fi

    # Create the user
    if ! useradd -m -c "$FULL_NAME" -s /bin/bash "$USERNAME"; then
        echo "Error: Could not create user $USERNAME"
        exit 1
    fi

    # Set the password
    echo "$USERNAME:$PASSWORD" | chpasswd
    if [ $? -ne 0 ]; then
        echo "Error: Could not set password for $USERNAME"
        exit 1
    fi

    # Create .ssh directory and authorized_keys file
    su - "$USERNAME" -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

    # Add the SSH public key
    if ! echo "$SSH_KEY" >> /home/$USERNAME/.ssh/authorized_keys; then
        echo "Error: Could not add SSH public key for $USERNAME"
        exit 1
    fi

    # Give permissions to switch to ubuntu user
    echo "$USERNAME ALL=(ALL) NOPASSWD: /bin/su ubuntu, /bin/su - ubuntu" > /etc/sudoers.d/$USERNAME
    chmod 0440 /etc/sudoers.d/$USERNAME

    echo "User $USERNAME successfully created with SSH access and permissions to switch to ubuntu user."
}

# Function to delete a user
delete_user() {
    # Check if username is provided
    if [ -z "$USERNAME" ]; then
        echo "Error: Username is required for user deletion."
        show_usage
        exit 1
    fi

    # Check if the user exists
    if ! id "$USERNAME" &>/dev/null; then
        echo "Error: User $USERNAME does not exist."
        exit 1
    fi

    # Delete the user and their home directory
    if ! userdel -r "$USERNAME"; then
        echo "Error: Could not delete user $USERNAME"
        exit 1
    fi

    # Remove the user's sudoers file if it exists
    if [ -f "/etc/sudoers.d/$USERNAME" ]; then
        rm "/etc/sudoers.d/$USERNAME"
    fi

    echo "User $USERNAME successfully deleted."
}

# Initialize variables
FULL_NAME=""
USERNAME=""
PASSWORD=""
SSH_KEY=""
ACTION=""

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--create)
            ACTION="create"
            shift
            ;;
        -d|--delete)
            ACTION="delete"
            shift
            ;;
        -n|--name)
            FULL_NAME="$2"
            shift 2
            ;;
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if the script is running with root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Perform the requested action
case $ACTION in
    create)
        create_user
        ;;
    delete)
        delete_user
        ;;
    *)
        echo "Error: No action specified. Use -c to create or -d to delete a user."
        show_usage
        exit 1
        ;;
esac
