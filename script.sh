#!/bin/bash

display_info()    { echo -e "\e[34m[I]\e[0m $1"; }
display_success() { echo -e "\e[32m[S]\e[0m $1"; }
display_warning() { echo -e "\e[33m[W]\e[0m $1"; }
display_error()   { echo -e "\e[31m[E]\e[0m $1"; exit 1; }

print_detailed_help() {
  case "$1" in
    ssh-key)
      echo "Usage: $0 ssh-key"
      echo "Configure the SSH key for secure remote access."
      ;;
    ssh)
      echo "Usage: $0 ssh"
      echo "Fine-tune the SSH server settings."
      ;;
    docker)
      echo "Usage: $0 docker"
      echo "Install Docker for containerized applications."
      ;;
    system)
      echo "Usage: $0 system"
      echo "Update system's hostname, locale, and timezone settings."
      ;;
    environment)
      echo "Usage: $0 environment"
      echo "Set up a user-friendly shell and development tools."
      ;;
    reinstall)
      echo "Usage: $0 reinstall"
      echo "Perform a clean reinstallation of Debian."
      ;;
    bbr)
      echo "Usage: $0 bbr [-s]"
      echo "Optimize network performance with BBR. Use -s to apply system settings without kernel update."
      ;;
    caddy)
      echo "Usage: $0 caddy"
      echo "Install Caddy web server."
      ;;
    create-user)
      echo "Usage: $0 create-user [username] [password]"
      echo "Create a new user with sudo privileges. You need to provide a username and a password."
      ;;
    *)
      echo "Invalid command for detailed help. Here's the general usage:"
      print_help
      ;;
  esac
}

# 调整原始的 print_help 函数以简化输出
print_help() {
  cat << EOF
Usage: $0 <command> [options]

Available commands:
  ssh-key        Configure the SSH key for secure remote access.
  ssh            Fine-tune the SSH server settings.
  docker         Install Docker for containerized applications.
  system         Update system's hostname, locale and timezone settings.
  environment    Set up a user-friendly shell and development tools.
  reinstall      Perform a clean reinstallation of Debian.
  bbr            Optimize network performance with BBR.
  caddy          Install Caddy web server.
  create-user    Create a new user with sudo privileges.

For detailed help, use: $0 help <command>
EOF
}

if [[ ! -f "/etc/debian_version" && "$1" != "reinstall" ]]; then
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
  public_key='ssh-ed25519 ... i@i.ls'

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
  sudo usermod -aG sudo "$username"
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
  sudo systemctl restart ssh && display_info "SSH server restarted."
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
  install_package zsh curl && display_info "Essential packages installed."
  sudo curl -sSL https://bootstrap.pypa.io/get-pip.py | sudo python3 && display_info "pip installed."
  sudo pip3 install wakatime && display_info "wakatime installed."
  curl -o ~/.zshrc https://s.repo.host/addons/zshrc && display_info "zsh configuration file fetched."
  sudo chsh -s $(command -v zsh) "$current_user" && display_info "Default shell changed to zsh for '$current_user'."
  zsh
  display_success "Environment setup completed."
}

install_bbr() {
  display_info "Initializing BBR installation..."
  setup=$1
  [[ -f "/etc/debian_version" ]] || return
  if [[ "$setup" == "-s" ]]; then
    echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p && display_info "System control variables set."
  else
    curl -o /tmp/linux-headers.deb https://s.repo.host/addons/linux-headers.deb
    curl -o /tmp/linux-image.deb https://s.repo.host/addons/linux-image.deb
    sudo apt install /tmp/linux-*.deb && display_info "Kernel packages installed."
    rm /tmp/linux-*.deb
  fi
  display_success "BBR installation completed."
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
  mirror="http://deb.debian.org/debian"
  [[ $(curl -s api.baka.cafe?isCN) == '1' ]] && mirror="http://mirrors.ustc.edu.cn/debian"
  curl -sSL https://s.repo.host/addons/InstallNET.sh | sudo bash -s -- -d 12 -v 64 -a --mirror "$mirror" -p 'repo.host'
  display_success "Debian reinstallation process started."
}

install_caddy() {
  display_info "Initializing Caddy installation..."
  echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" | sudo tee -a /etc/apt/sources.list.d/caddy-fury.list
  sudo apt update && sudo apt install caddy
  display_success "Caddy installation completed."
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
  bbr)            shift; install_bbr "$@" ;;
  caddy)          install_caddy ;;
  create-user)    shift; create_user "$@" ;;
  *)              print_help ;;
esac
