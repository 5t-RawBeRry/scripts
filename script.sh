#!/bin/bash

display_info()    { echo -e "\e[34m[I]\e[0m $1"; }
display_success() { echo -e "\e[32m[S]\e[0m $1"; }
display_warning() { echo -e "\e[33m[W]\e[0m $1"; }
display_error()   { echo -e "\e[31m[E]\e[0m $1"; exit 1; }

print_help() {
  cat << EOF
Usage: $0 <command> [options]

Available commands:
  ssh-key        Configure the SSH key.
  ssh            Configure the SSH server.
  docker         Install Docker.
  system         Configure system settings.
  environment    Setup the environment.
  reinstall      Reinstall Debian.
  bbr            Install BBR.
  caddy          Install Caddy.
  create-user    Create a new user.

For more details, specify a command. Example: $0 ssh-key
EOF
  exit 0
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
  sudo apt update -q > /dev/null
  for package in "$@"; do
    dpkg -l | grep -qw "$package" || (sudo apt install -yq "$package" > /dev/null && display_success "Package '$package' installed.")
  done
}

configure_ssh_key() {
  ssh_dir=~/.ssh
  authorized_keys="$ssh_dir/authorized_keys"
  public_key='ssh-ed25519 ... i@i.ls'

  [[ -d "$ssh_dir" ]] || mkdir -p "$ssh_dir"
  [[ -f "$authorized_keys" ]] || touch "$authorized_keys"
  grep -q "$public_key" "$authorized_keys" || echo "$public_key" >> "$authorized_keys"
}

create_user() {
  username=$1
  password=$2

  id -u "$username" >/dev/null 2>&1 && return
  sudo useradd -m -s /bin/bash "$username"
  [[ -n "$password" ]] && echo "$username:$password" | sudo chpasswd
  sudo usermod -aG sudo "$username"
  command -v docker >/dev/null 2>&1 && sudo usermod -aG docker "$username"
}

configure_ssh() {
  sudo sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' \
         -e 's/#PubkeyAuthentication/PubkeyAuthentication/g' \
         -e 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' \
         -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' \
         /etc/ssh/sshd_config
  sudo systemctl restart ssh
}

configure_system() {
  sudo hostnamectl set-hostname EuangeLion
  sudo sed -i 's/localhost/EuangeLion localhost/g' /etc/hosts
  sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  sudo locale-gen
  sudo timedatectl set-timezone Asia/Hong_Kong
}

setup_environment() {
  install_package zsh curl
  sudo curl -sSL https://bootstrap.pypa.io/get-pip.py | sudo python3
  sudo pip3 install wakatime
  curl -o ~/.zshrc https://s.repo.host/addons/zshrc
  sudo chsh -s $(command -v zsh) "$current_user"
  zsh
}

install_bbr() {
  setup=$1
  [[ -f "/etc/debian_version" ]] || return
  if [[ "$setup" == "-s" ]]; then
    echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
  else
    curl -o /tmp/linux-headers.deb https://s.repo.host/addons/linux-headers.deb
    curl -o /tmp/linux-image.deb https://s.repo.host/addons/linux-image.deb
    sudo apt install /tmp/linux-*.deb
    rm /tmp/linux-*.deb
  fi
}

install_docker() {
  command -v docker >/dev/null 2>&1 && return
  curl -sSL https://get.docker.com | sh
  [[ $current_user != "root" ]] && sudo usermod -aG docker "$current_user"
}

reinstall_debian() {
  mirror="http://deb.debian.org/debian"
  [[ $(curl -s api.baka.cafe?isCN) == '1' ]] && mirror="http://mirrors.ustc.edu.cn/debian"
  curl -sSL https://s.repo.host/addons/InstallNET.sh | sudo bash -s -- -d 12 -v 64 -a --mirror "$mirror" -p 'repo.host'
}

install_caddy() {
  install_package gnupg apt-transport-https lsb-release
  curl -sSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/caddy.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/caddy.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/caddy.list >/dev/null
  install_package caddy
}

current_user=$(whoami)
check_root_privileges
[[ -z "$1" ]] && print_help

case "$1" in
  ssh-key)         configure_ssh_key ;;
  ssh)             configure_ssh ;;
  docker)          install_docker ;;
  system)          configure_system ;;
  environment)     setup_environment ;;
  reinstall)       reinstall_debian ;;
  bbr)             shift; install_bbr "$@" ;;
  caddy)           install_caddy ;;
  create-user)     shift; create_user "$@" ;;
  *)               print_help ;;
esac
