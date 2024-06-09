#!/bin/bash

# Define color schemes
success_color="\e[32m"
error_color="\e[31m"
highlight_color="\e[33m"
heading_color="\e[35m"
normal_color="\e[0m"

# Function to display error messages and exit
display_error() {
    echo -e "${error_color}Error: $1${normal_color}"
    exit 1
}

# Function to display a message in a specific color
display_message() {
    color=$1
    message=$2
    echo -e "${color}${message}${normal_color}"
}

# Check current setting and apply new setting if necessary
apply_config() {
    current_setting=$(grep "^$2" $3)
    display_message $heading_color "Current setting for $2 in $3: $current_setting"
    if [[ "$current_setting" != "$2 $4" ]]; then
        sed -i "s|^$2 .*|$2 $4|" $3 || display_error "$5"
    fi
}

# Ensure the script is run as root
if [[ "$(id -u)" -ne 0 ]]; then
   display_error "This script must be run as root."
fi

# Configuration definitions
ssh_dir=/root/.ssh
authorized_keys="$ssh_dir/authorized_keys"
sshd_config="/etc/ssh/sshd_config"
sshd_config_backup="$sshd_config.bak"
motd_file="/etc/motd"
trace_info=$(curl -s https://cloudflare.com/cdn-cgi/trace)
location=$(echo "$trace_info" | grep loc= | cut -d '=' -f2)
random_password=$(cat /proc/sys/kernel/random/uuid)
random_part=$(tr -dc 'A-Z0-9' </dev/urandom | head -c 8)
colo=$(echo "$trace_info" | grep colo= | cut -d '=' -f2)
new_hostname="$colo-SRV-$random_part"

# Determine region and repository
repo_url="https://mirror-cdn.xtom.com"
repo_region="Non-China region"
if [[ "$location" == "CN" ]]; then
    repo_url="https://mirrors.ustc.edu.cn"
    repo_region="China region"
fi

# Collect public key information
public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMj1ZURxNE8MV9OkwEYruwBNQDgn61k0u2wQNWIxu7P"
github_user="5t-RawBeRry"
if [[ "$1" ]]; then
    github_user=$1
    public_key=$(curl -s https://github.com/$github_user.keys | head -n 1)
    [[ -z "$public_key" ]] && display_error "Failed to retrieve public key from GitHub ($github_user)."
fi

# Display configuration summary and request confirmation
display_message $heading_color "\nConfiguration Summary:\n"
display_message $heading_color "Public Key: ${highlight_color}$github_user${normal_color} (${highlight_color}$public_key${normal_color})"
display_message $heading_color "Source: $repo_region, using ${highlight_color}$repo_url${normal_color} mirror"
display_message $heading_color "Password: Root user's password will be reset to ${highlight_color}$random_password${normal_color}"
display_message $heading_color "Hostname: ${highlight_color}$new_hostname${normal_color}"
display_message $heading_color "Confirm Changes: Please type '${highlight_color}yes${normal_color}' to continue (${highlight_color}yes${normal_color}/${highlight_color}no${normal_color})"

read confirmation
if [[ "$confirmation" != "yes" ]]; then
    echo "Configuration cancelled."
    exit
fi

# Execute configuration
display_message $highlight_color "\nExecuting Configuration..."
mkdir -p $ssh_dir
echo "$public_key" > "$authorized_keys"
cp $sshd_config $sshd_config_backup

# Apply SSHD configurations
apply_config "PermitRootLogin" "PermitRootLogin" $sshd_config "prohibit-password" "Failed to modify PermitRootLogin."
apply_config "PasswordAuthentication" "PasswordAuthentication" $sshd_config "no" "Failed to disable password authentication."
apply_config "AllowTcpForwarding" "AllowTcpForwarding" $sshd_config "yes" "Failed to modify AllowTcpForwarding."

# Clear and update /etc/motd
echo -n > $motd_file
echo "# 5t-RawBeRry's SRV." > $motd_file

# Configure sources.list using sed to replace only the URL
sed -i "s|http[s]*://[^/]*/|$repo_url/|g" /etc/apt/sources.list

# Update and upgrade the system
apt update && apt upgrade -y
systemctl restart sshd
hostnamectl set-hostname $new_hostname
echo "root:$random_password" | chpasswd

# Update /etc/hosts
sed -i "s/^127\.0\.0\.1.*$/127.0.0.1       $new_hostname localhost localhost.localdomain/" /etc/hosts
sed -i "s/^::1.*$/::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback/" /etc/hosts

# Enable BBR and additional network optimizations
display_message $highlight_color "\nEnabling BBR and network optimizations..."
cat <<EOF >> /etc/sysctl.conf
vm.swappiness = 0
fs.file-max = 1024000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 1024000
net.core.default_qdisc = fq_pie
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_announce = 2
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_keepalive_time = 10
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv4.tcp_slow_start_after_idle = 0
EOF
sysctl -p

# Download and install specified deb packages
deb_urls=(
    "https://p.repo.host/c1p2/https://static.codemao.cn/bfs/ae70ac43-9a38-420d-b33a-20477ea55fca.deb"
    "https://p.repo.host/c1p2/https://static.codemao.cn/bfs/680e7312-3845-434e-9532-34f803111b91.deb"
    "https://p.repo.host/c1p2/https://static.codemao.cn/bfs/6efaf83f-b612-47a9-b892-0e34c1f9a3e5.deb"
)

for url in "${deb_urls[@]}"; do
    wget $url -P /tmp/
    deb_file="/tmp/$(basename $url)"
    dpkg -i $deb_file || display_error "Failed to install $deb_file"
done

display_message $highlight_color "plx remove linux-image-amd64 || linux-image-cloud-amd64"
display_message $success_color "Debian configuration and package installation completed successfully!"
