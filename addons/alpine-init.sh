#!/bin/sh

# Define color schemes
success_color="\e[32m"
error_color="\e[31m"
highlight_color="\e[33m"
heading_color="\e[35m"
normal_color="\e[0m"

# Function to display error messages and exit
display_error() {
    echo -e "${error_color}Error: $1${normal_color}";
    exit 1;
}

# Execute commands silently, log only on error
execute_silently() {
    $1 > /dev/null 2>&1 || display_error "$2"
}

# Check current setting and apply new setting if necessary
apply_config() {
    current_setting=$(grep "^$2" $3)
#    echo "Current setting for $2 in $3: $current_setting"
    if [ "$current_setting" != "$2 $4" ]; then
        sed_command="sed -i 's/^$2 .*/$2 $4/' $3"
#        echo "Applying: $sed_command"
#        echo "New setting for $2 in $3: $new_setting"
        eval $sed_command
        if [ $? -ne 0 ]; then
            display_error "$5"
        fi
    fi
}

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
   display_error "This script must be run as root."
fi

# Configuration definitions
ssh_dir=~/.ssh
authorized_keys="$ssh_dir/authorized_keys"
sshd_config="/etc/ssh/sshd_config"
sshd_config_backup="$sshd_config.bak"
motd_file="/etc/motd"
trace_info=$(curl -s https://cloudflare.com/cdn-cgi/trace)
location=$(echo "$trace_info" | grep loc= | cut -d '=' -f2)
random_password=$(cat /proc/sys/kernel/random/uuid)
random_part=$(tr -dc 'A-Z0-9' </dev/urandom | head -c 8)
colo=$(echo "$trace_info" | grep colo= | cut -d '=' -f2)
new_hostname="SRV-$colo-$random_part"

# Determine region and repository
repo_url="http://mirror-cdn.xtom.com/alpine"
repo_region="Non-China region"
if [ "$location" = "CN" ]; then
    repo_url="http://mirrors.ustc.edu.cn/alpine"
    repo_region="China region"
fi

# Collect public key information
public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMj1ZURxNE8MV9OkwEYruwBNQDgn61k0u2wQNWIxu7P"
github_user="5t-RawBeRry"
if [ "$1" ]; then
    github_user=$1
    public_key=$(curl -s https://github.com/$github_user.keys | head -n 1)
    if [ -z "$public_key" ]; then
        display_error "Failed to retrieve public key from GitHub ($github_user)."
    fi
fi

# Display configuration summary and request confirmation
echo -e "\n${heading_color}Configuration Summary:${normal_color}\n"
echo -e "${heading_color}Public Key:${normal_color} ${highlight_color}$github_user${normal_color} (${highlight_color}$public_key${normal_color})"
echo -e "${heading_color}Source:${normal_color} $repo_region, using ${highlight_color}$repo_url${normal_color} mirror"
echo -e "${heading_color}Password:${normal_color} Root user's password will be reset to ${highlight_color}$random_password${normal_color}"
echo -e "${heading_color}Hostname:${normal_color} ${highlight_color}$new_hostname${normal_color}"
echo -e "${heading_color}Confirm Changes:${normal_color} Please type '${highlight_color}yes${normal_color}' to continue (${highlight_color}yes${normal_color}/${highlight_color}no${normal_color})"

read confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Configuration cancelled."
    exit
fi

# Execute configuration
echo -e "\nExecuting Configuration..."
execute_silently "mkdir -p $ssh_dir" "Failed to create SSH directory."
echo "$public_key" > "$authorized_keys"
execute_silently "cp $sshd_config $sshd_config_backup" "Failed to backup sshd_config."
apply_config "PermitRootLogin" "PermitRootLogin" $sshd_config "prohibit-password" "Failed to modify PermitRootLogin."
apply_config "PasswordAuthentication" "PasswordAuthentication" $sshd_config "no" "Failed to disable password authentication."
apply_config "AllowTcpForwarding" "AllowTcpForwarding" $sshd_config "yes" "Failed to modify AllowTcpForwarding."
execute_silently "echo -n > $motd_file" "Failed to clear /etc/motd."
echo "# Added by script
$repo_url/edge/main
$repo_url/edge/community
$repo_url/edge/testing" > "/etc/apk/repositories"
execute_silently "apk update" "Failed to update software sources."
execute_silently "apk upgrade" "Failed to upgrade system."
execute_silently "/etc/init.d/sshd restart" "Failed to restart SSH service."
execute_silently "echo 'root:$random_password' | chpasswd" "Failed to reset root password."
execute_silently "hostname $new_hostname" "Failed to change hostname."

echo -e "${success_color}Alpine configuration completed successfully!${normal_color}"
