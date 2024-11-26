#!/bin/bash
# Description: This script is used to manage users in the system and AWS.
# Author: @barckcode (https://github.com/barckcode)

# Function to display script usage
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -c, --create             Create a new user (requires -n, -u, -p, -k)"
    echo "  -d, --delete             Delete an existing user (requires -u)"
    echo "  -n, --name <name>        Full name of the user (in quotes)"
    echo "  -u, --username <user>    Username for the system, AWS, and MongoDB"
    echo "  -p, --password <pass>    Temporary password for the user"
    echo "  -k, --key <public_key>   SSH public key (in quotes)"
    echo "  -m, --mongo <env>        MongoDB environments to create user (dev, pre, pro, both). Default: both"
    echo
    echo "Examples:"
    echo "  Create user: $0 -c -n \"Gandalf the Grey\" -u ggrey -p \"1Temp0r@l\" -k \"ssh-rsa AAAA...\" -m dev"
    echo "  Delete user: $0 -d -u ggrey"
}

# Function to read MongoDB configuration
read_mongo_config() {
    if [ ! -f "mongo.config" ]; then
        echo "Error: mongo.config file not found"
        exit 1
    fi
    source ~/scripts/mongo.config
}

# Function to create MongoDB user with admin privileges
create_mongo_user() {
    local host=$1
    local admin_user=$2
    local admin_password=$3
    local new_user=$4
    local new_password=$5

    if ! mongosh --host "$host" --username "$admin_user" --password "$admin_password" --authenticationDatabase admin <<EOF
use admin
db.createUser({
  user: "$new_user",
  pwd: "$new_password",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" },
    { role: "clusterAdmin", db: "admin" }
  ]
})
EOF
    then
        echo "Error: Failed to create MongoDB user $new_user"
        return 1
    fi
}

# Function to delete MongoDB user
delete_mongo_user() {
    local host=$1
    local admin_user=$2
    local admin_password=$3
    local delete_user=$4

    if ! mongosh --host "$host" --username "$admin_user" --password "$admin_password" --authenticationDatabase admin <<EOF
use admin
db.dropUser("$delete_user")
EOF
    then
        echo "Error: Failed to delete MongoDB user $delete_user"
        return 1
    fi
}

# Function to create a user in the system, AWS, and MongoDB
create_user() {
    # Check if all required arguments are provided
    if [ -z "$FULL_NAME" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$SSH_KEY" ]; then
        echo "Error: Missing required arguments for user creation."
        show_usage
        exit 1
    fi

    # Create the system user
    if ! useradd -m -c "$FULL_NAME" -s /bin/bash "$USERNAME"; then
        echo "Error: Could not create system user $USERNAME"
        exit 1
    fi

    # Set the system password
    echo "$USERNAME:$PASSWORD" | chpasswd
    if [ $? -ne 0 ]; then
        echo "Error: Could not set system password for $USERNAME"
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

    # Create AWS user
    if ! aws iam create-user --user-name "$USERNAME"; then
        echo "Error: Could not create AWS user $USERNAME"
        exit 1
    fi

    # Create AWS login profile with temporary password
    if ! aws iam create-login-profile --user-name "$USERNAME" --password "$PASSWORD" --password-reset-required; then
        echo "Error: Could not create AWS login profile for $USERNAME"
        exit 1
    fi

    # Attach policy to allow user to change their own password
    aws iam attach-user-policy --user-name "$USERNAME" --policy-arn arn:aws:iam::aws:policy/IAMUserChangePassword

    # Add user to the admins group
    if ! aws iam add-user-to-group --user-name "$USERNAME" --group-name admins; then
        echo "Error: Could not add user $USERNAME to admins group"
        exit 1
    fi

    # Create MongoDB users with admin privileges
    read_mongo_config
    if [ "$MONGO_ENV" = "dev" ] || [ "$MONGO_ENV" = "both" ]; then
        create_mongo_user "$MONGO_HOST_DEV" "$MONGO_USER_DEV" "$MONGO_PASSWORD_DEV" "$USERNAME" "$PASSWORD"
        echo "MongoDB admin user created in dev environment"
    fi
    if [ "$MONGO_ENV" = "pre" ] || [ "$MONGO_ENV" = "both" ]; then
        create_mongo_user "$MONGO_HOST_PRE" "$MONGO_USER_PRE" "$MONGO_PASSWORD_PRE" "$USERNAME" "$PASSWORD"
        echo "MongoDB admin user created in pre environment"
    fi
    if [ "$MONGO_ENV" = "pro" ] || [ "$MONGO_ENV" = "both" ]; then
        create_mongo_user "$MONGO_HOST_PRO" "$MONGO_USER_PRO" "$MONGO_PASSWORD_PRO" "$USERNAME" "$PASSWORD"
        echo "MongoDB admin user created in pro environment"
    fi

    echo "User $USERNAME successfully created with admin privileges in system, AWS, and specified MongoDB environments."
}

# Function to delete a user from the system, AWS, and MongoDB
delete_user() {
    # Check if username is provided
    if [ -z "$USERNAME" ]; then
        echo "Error: Username is required for user deletion."
        show_usage
        exit 1
    fi

    # Check if the system user exists
    if id "$USERNAME" &>/dev/null; then
        # Delete the system user and their home directory
        if ! userdel -r "$USERNAME"; then
            echo "Error: Could not delete system user $USERNAME"
            exit 1
        fi

        # Remove the user's sudoers file if it exists
        if [ -f "/etc/sudoers.d/$USERNAME" ]; then
            rm "/etc/sudoers.d/$USERNAME"
        fi
    else
        echo "Warning: System user $USERNAME does not exist."
    fi

    # Check if the AWS user exists
    if aws iam get-user --user-name "$USERNAME" &>/dev/null; then
        # Remove user from admins group
        aws iam remove-user-from-group --user-name "$USERNAME" --group-name admins

        # Delete login profile
        aws iam delete-login-profile --user-name "$USERNAME"

        # Detach all policies from the user
        for policy in $(aws iam list-attached-user-policies --user-name "$USERNAME" --query 'AttachedPolicies[*].PolicyArn' --output text); do
            aws iam detach-user-policy --user-name "$USERNAME" --policy-arn "$policy"
        done

        # Delete the AWS user
        if ! aws iam delete-user --user-name "$USERNAME"; then
            echo "Error: Could not delete AWS user $USERNAME"
            exit 1
        fi
    else
        echo "Warning: AWS user $USERNAME does not exist."
    fi

    # Delete MongoDB users
    read_mongo_config
    delete_mongo_user "$MONGO_HOST_DEV" "$MONGO_USER_DEV" "$MONGO_PASSWORD_DEV" "$USERNAME"
    delete_mongo_user "$MONGO_HOST_PRE" "$MONGO_USER_PRE" "$MONGO_PASSWORD_PRE" "$USERNAME"
    delete_mongo_user "$MONGO_HOST_PRO" "$MONGO_USER_PRO" "$MONGO_PASSWORD_PRO" "$USERNAME"

    echo "User $USERNAME successfully deleted from system, AWS, and MongoDB environments."
}

# Initialize variables
FULL_NAME=""
USERNAME=""
PASSWORD=""
SSH_KEY=""
ACTION=""
MONGO_ENV="both"

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
        -m|--mongo)
            MONGO_ENV="$2"
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
