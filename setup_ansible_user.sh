#!/bin/bash

# --- Configuration Variables ---
USERNAME="ansible"
HOME_DIR="/home/${USERNAME}"
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPfO2yocBrR4Jmzs52KmzFIWU2Zz+ctX4yzersOhem8 mechanicus@ansible"

# --- Safety Checks ---
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root or using sudo."
   exit 1
fi

echo "============================================="
echo "=== Starting Ansible User Setup Script ==="
echo "============================================="


# Step 1: Add the user 'ansible' with a home directory
echo -e "\n[STEP 1/4] Adding user '$USERNAME' and setting up home directory..."
if id "$USERNAME" &>/dev/null; then
    echo "   -> User $USERNAME already exists. Skipping creation."
else
    # Create the user (-m ensures the home directory is created)
    useradd -m -s /bin/bash "$USERNAME"
    echo "   -> User '$USERNAME' created successfully."

    # Set a temporary password (optional, but good practice)
    # NOTE: In a real environment, you might integrate this with a secret vault.
    # passwd "$USERNAME"
    # echo "   -> Password prompt initiated for $USERNAME (you will need to enter and confirm it)."
fi


# Step 2: Set up SSH keys
echo -e "\n[STEP 2/4] Configuring SSH keys in $HOME_DIR/.ssh..."

# Create .ssh directory if it doesn't exist, ensuring correct ownership/permissions
mkdir -p "${HOME_DIR}/.ssh"
chown ${USERNAME}:${USERNAME} "${HOME_DIR}/.ssh"
chmod 700 "${HOME_DIR}/.ssh"

# Append the key to authorized_keys
echo "$SSH_KEY" >> "${HOME_DIR}/.ssh/authorized_keys"

# Set correct permissions and ownership on the key file
chown ${USERNAME}:${USERNAME} "${HOME_DIR}/.ssh/authorized_keys"
chmod 600 "${HOME_DIR}/.ssh/authorized_keys"

echo "   -> SSH Key added successfully."


# Step 3: Add NOPASSWD sudo access
echo -e "\n[STEP 3/4] Adding passwordless sudo privileges for '$USERNAME'..."

# The safest way to modify /etc/sudoers is using visudo, but that's hard to script.
# We will use a basic check and append the line structure.
if grep -q "^${USERNAME} ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "   -> Sudo entry already exists in /etc/sudoers. Skipping."
else
    # Append the rule to ensure it's included (Requires careful root execution)
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
    if [ $? -eq 0 ]; then
        echo "   -> Successfully appended NOPASSWD rule for '$USERNAME'."
    else
        echo "   !!! ERROR: Failed to append rule to /etc/sudoers. Manual intervention required. !!!"
    fi
fi


# Step 4: Ensure correct ownership across the entire home directory
echo -e "\n[STEP 4/4] Setting root ownership recursively on $HOME_DIR..."
chown -R ${USERNAME}:${USERNAME} "${HOME_DIR}"

if [ $? -eq 0 ]; then
    echo "   -> Ownership successfully reset for all files under $HOME_DIR."
else
    echo "   !!! WARNING: Could not reset ownership. Check permissions manually! !!!"
fi


# --- Conclusion ---
echo -e "\n============================================="
echo "✅ Setup Complete!"
echo "The user '$USERNAME' has been configured:"
echo " - SSH Key added and protected."
echo " - Passwordless sudo access granted."
echo " - Home directory ownership verified."
echo "============================================="
