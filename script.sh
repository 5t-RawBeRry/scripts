#!/bin/bash

[[ $0 != bash ]] && script_name=$0 || script_name="curl -sSL https://s.repo.host/script.sh | bash -s --"

display_info()    { echo -e "\e[34m[I]\e[0m $1"; }
display_success() { echo -e "\e[32m[S]\e[0m $1"; }
display_warning() { echo -e "\e[33m[W]\e[0m $1"; }
display_error()   { echo -e "\e[31m[E]\e[0m $1"; exit 1; }

print_detailed_help() {
  case "$1" in
    ssh-key)
      echo "Usage: $script_name ssh-key"
      echo "Configure the SSH key for secure remote access."
      ;;
    ssh)
      echo "Usage: $script_name ssh"
      echo "Fine-tune the SSH server settings."
      ;;
    docker)
      echo "Usage: $script_name docker"
      echo "Install Docker for containerized applications."
      ;;
    system)
      echo "Usage: $script_name system"
      echo "Update system's hostname, locale, and timezone settings."
      ;;
    environment)
      echo "Usage: $script_name environment"
      echo "Set up a user-friendly shell and development tools."
      ;;
    reinstall)
      echo "Usage: $script_name reinstall"
      echo "Perform a clean reinstallation of Debian."
      ;;
    bbr)
      echo "Usage: $script_name bbr"
      echo "Optimize network performance with BBR."
      ;;
    zen)
      echo "Usage: $script_name zen [-lqx]"
      echo "Install kernel-zen. Use -lqx to kernel-lqx."
      ;;
    swap)
      echo "Usage: $script_name swap [-zram]"
      echo "Add SWAP. Use -zram to ZRAM."
      ;;
    warp)
      echo "Usage: $script_name warp [-go]"
      echo "Use Cloudflare-WARP [Zero Trust]. Use -go to WARP-GO."
      ;;
    caddy)
      echo "Usage: $script_name caddy"
      echo "Install Caddy web server."
      ;;
    create-user)
      echo "Usage: $script_name create-user [username] [password]"
      echo "Create a new user with sudo privileges. You need to provide a username and a password."
      ;;
    *)
      echo "Invalid command for detailed help. Here's the general usage:"
      print_help
      ;;
  esac
}

print_help() {
  cat << EOF
Usage: $script_name <command> [options]

Available commands:
  ssh-key        Configure the SSH key for secure remote access.
  ssh            Fine-tune the SSH server settings.
  docker         Install Docker for containerized applications.
  system         Update system's hostname, locale and timezone settings.
  environment    Set up a user-friendly shell and development tools.
  reinstall      Perform a clean reinstallation of Debian.
  bbr            Optimize network performance with BBR.
  zen            Install ZEN kernel.
  swap           Add SWAP or ZRAM.
  warp           Cloudflare WARP [Zero Trust].
  caddy          Install Caddy web server.
  create-user    Create a new user with sudo privileges.

For detailed help, use: $0 help <command>
EOF
}

if [[ ! -f "/etc/debian_version" && "$1" != "reinstall" && "$1" != "ssh-key" && "$1" != "ssh" && "$1" != "create-user" ]]; then
  display_error "Unsupported system. Script for Debian only."
fi

check_root_privileges() {
  if [[ $EUID -ne 0 ]]; then
    sudo -v || display_error "Failed to obtain sudo privileges."
  fi
  command -v sudo >/dev/null 2>&1 || (install_package sudo && display_success "sudo installed.")
}

install_package() {
  display_info "Updating package lists..."
  sudo apt update -q > /dev/null
  display_info "Installing requested packages..."
  for package in "$@"; do
    dpkg -l | grep -qw "$package" || (sudo apt install -yq "$package" > /dev/null && display_success "Package '$package' installed.")
  done
}

configure_ssh_key() {
  display_info "Initializing SSH key configuration..."
  ssh_dir=~/.ssh
  authorized_keys="$ssh_dir/authorized_keys"
  public_key='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMj1ZURxNE8MV9OkwEYruwBNQDgn61k0u2wQNWIxu7P i@i.ls'

  [[ -d "$ssh_dir" ]] || mkdir -p "$ssh_dir" && display_info "SSH directory created."
  [[ -f "$authorized_keys" ]] || touch "$authorized_keys" && display_info "Authorized keys file created."
  grep -q "$public_key" "$authorized_keys" || echo "$public_key" >> "$authorized_keys"
  display_success "SSH key configured successfully."
}

create_user() {
  display_info "Initializing user creation..."
  username=$1
  password=$2

  id -u "$username" >/dev/null 2>&1 && return
  sudo useradd -m -s /bin/bash "$username" && display_info "User '$username' created."
  [[ -n "$password" ]] && echo "$username:$password" | sudo chpasswd && display_info "Password set for user '$username'."
  if [[ -f /etc/arch-release ]]; then
    sudo usermod -aG wheel "$username"
  else
    sudo usermod -aG sudo "$username"
  fi
  command -v docker >/dev/null 2>&1 && sudo usermod -aG docker "$username"
  display_success "User '$username' created and configured successfully."
}

configure_ssh() {
  display_info "Initializing SSH server configuration..."
  sudo sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' \
         -e 's/#PubkeyAuthentication/PubkeyAuthentication/g' \
         -e 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' \
         -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' \
         /etc/ssh/sshd_config && display_info "SSH configuration file updated."
  sudo systemctl restart sshd && display_info "SSHD server restarted."
  display_success "SSH server configured successfully."
}

configure_system() {
  display_info "Initializing system configuration..."
  sudo hostnamectl set-hostname EuangeLion && display_info "Hostname set to 'EuangeLion'."
  sudo sed -i 's/localhost/EuangeLion localhost/g' /etc/hosts && display_info "Hosts file updated."
  sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen && display_info "Locale settings updated."
  sudo locale-gen && display_info "Locale generated."
  sudo timedatectl set-timezone Asia/Hong_Kong && display_info "Timezone set to 'Asia/Hong_Kong'."
  display_success "System settings configured successfully."
}

setup_environment() {
  display_info "Initializing environment setup..."
  install_package fish && display_info "Essential packages installed."
  sudo chsh -s $(command -v fish) "$current_user" && display_info "Default shell changed to fish for '$current_user'."
  fish
  display_success "Environment setup completed."
}

install_bbr() {
  [[ -f "/etc/debian_version" ]] || return
  sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup
  sudo bash -c 'echo -n > /etc/sysctl.conf'
  sudo bash -c 'cat << EOF > /etc/sysctl.conf
vm.swappiness = 0
fs.file-max = 1024000
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
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
EOF'
  sudo sysctl -p && display_info "Sysctl configuration updated successfully!"
  display_success "BBR enable completed."
}

install_docker() {
  display_info "Initializing Docker installation..."
  command -v docker >/dev/null 2>&1 && return
  curl -sSL https://get.docker.com | sh && display_info "Docker installed."
  [[ $current_user != "root" ]] && sudo usermod -aG docker "$current_user" && display_info "User '$current_user' added to docker group."
  display_success "Docker installation completed."
}

reinstall_debian() {
  display_info "Initializing Debian reinstallation..."
  curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh | bash -s --  -debian 12 -pwd 'Kilin111' -filesystem "xfs" -swap "512" -mirror "http://mirror-cdn.xtom.com"
}

install_zen() {
  if [[ "$1" == "-lqx" ]]; then
    curl -s 'https://liquorix.net/install-liquorix.sh' | sudo bash
  else
    sudo apt install gpg wget -y
    wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
    sudo apt update && sudo apt install linux-xanmod-x64v4
  fi
  display_success "ZEN installation completed."
}

add_swap() {
  if [[ "$1" == "-zram" ]]; then
    curl -sSL 'https://s.repo.host/addons/zram.sh' -o /tmp/zram.sh && chmod +x /tmp/zram.sh && sudo bash /tmp/zram.sh
  else
    curl -sSL 'https://s.repo.host/addons/swap.sh' -o /tmp/swap.sh && chmod +x /tmp/swap.sh && sudo bash /tmp/swap.sh
  fi
  rm /tmp/zram.sh /tmp/swap.sh
}

install_caddy() {
  display_info "Initializing Caddy installation..."
  install_package gnupg apt-transport-https lsb-release ca-certificates
  curl -sSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/caddy.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/caddy.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/caddy.list
  install_package caddy
  display_success "Caddy installation completed."
}

enable_warp() {
  if [[ "$1" == "-go" ]]; then
    curl -sSL 'https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh' -o /tmp/warp-go.sh && chmod +x /tmp/warp-go.sh && sudo bash /tmp/warp-go.sh
  else
    curl -sSL 'https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh' -o /tmp/menu.sh && chmod +x /tmp/menu.sh && sudo bash /tmp/menu.sh
  fi
  rm /tmp/warp-go.sh /tmp/menu.sh
}

current_user=$(whoami)

case "$1" in
  help)           shift; print_detailed_help "$@" ;;
  ssh-key)        configure_ssh_key ;;
  ssh)            configure_ssh ;;
  docker)         install_docker ;;
  system)         configure_system ;;
  environment)    setup_environment ;;
  reinstall)      reinstall_debian ;;
  bbr)            install_bbr ;;
  zen)            shift; install_zen "$@" ;;
  swap)           shift; add_swap "$@" ;;
  warp)           shift; enable_warp "$@" ;;
  caddy)          install_caddy ;;
  create-user)    shift; create_user "$@" ;;
  *)              print_help ;;
esac
