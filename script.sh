#!/bin/bash

# Function to display various types of messages
display_message() {
  local type="$1"
  local message="$2"
  local color=""

  case "$type" in
    info)     color="\e[34m[I]\e[0m";;
    success)  color="\e[32m[S]\e[0m";;
    warning)  color="\e[33m[W]\e[0m";;
    error)    color="\e[31m[E]\e[0m";;
  esac

  echo -e "$color $message"
}

# Helper function to check if a command exists
command_exists() {
  command -v "$1" > /dev/null 2>&1
}

# Helper function to download files
download_file() {
  local url="$1"
  local dest="$2"
  curl -sSL "$url" -o "$dest"
}

# Check if the script is running with root privileges
check_root_privileges() {
  if [[ $EUID -ne 0 && ! command_exists sudo ]]; then
    display_message error "Please install sudo or run this script with root privileges."
    exit 1
  fi
}

# Function to install a package using the appropriate package manager
install_package() {
  local package_manager=""

  # Determine the package manager
  if command_exists apt; then
    package_manager="apt"
    display_message info "Updating $package_manager package lists..."
    sudo "$package_manager" update > /dev/null 2>&1
    display_message success "$package_manager package lists updated."
  elif command_exists yum; then
    package_manager="yum"
  else
    display_message error "Unsupported package manager."
    exit 1
  fi

  # Install the packages
  for package in "$@"; do
    display_message info "Installing package '$package'..."
    sudo "$package_manager" install -y "$package" > /dev/null 2>&1
    display_message success "Package '$package' installed."
  done
}

configure_ssh_key() {
  local ssh_dir=~/.ssh
  local authorized_keys="$ssh_dir/authorized_keys"
  local public_key='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMj1ZURxNE8MV9OkwEYruwBNQDgn61k0u2wQNWIxu7P i@i.ls'

  if [[ -d "$ssh_dir" ]]; then
    display_success "The \e[1m$ssh_dir\e[0m directory already exists."
  else
    display_info "Creating the \e[1m$ssh_dir\e[0m directory..."
    mkdir -p "$ssh_dir"
  fi

  if [ -f "$authorized_keys" ]; then
    display_success "The \e[1m$authorized_keys\e[0m file already exists."
  else
    display_info "Creating the \e[1m$authorized_keys\e[0m file..."
    touch "$authorized_keys"
  fi

  if grep -q "$public_key" "$authorized_keys"; then
    display_success "The public key already exists in \e[1mauthorized_keys\e[0m."
  else
    echo "$public_key" >> "$authorized_keys"
    display_success "SSH public key added to \e[1mauthorized_keys\e[0m."
  fi
}

# Function to create a new user
create_user() {
  local username=$1
  local password=$2

  if id -u "$username" >/dev/null 2>&1; then
    display_error "User '$username' already exists. Skipping user creation."
    return
  fi

  display_info "Creating user '$username'..."
  sudo useradd -m -s /bin/bash "$username"
  display_success "User '$username' created."

  if [[ -n "$password" ]]; then
    display_info "Setting password for user '$username'..."
    echo "$username:$password" | sudo chpasswd
    display_success "Password set for user '$username'."
  fi

  display_info "Granting sudo privileges to user '$username'..."
  sudo usermod -aG sudo "$username"
  display_success "Sudo privileges granted to user '$username'."

  if command -v docker >/dev/null 2>&1; then
    display_info "Granting docker privileges to user '$username'..."
    sudo usermod -aG docker "$username"
    display_success "Docker privileges granted to user '$username'."
  fi
}

# Function to configure SSH server
configure_ssh() {
  display_info "Updating SSH server configuration: disabling root login, enabling public key authentication, and disabling password authentication."
  sudo sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' \
         -e 's/#PubkeyAuthentication/PubkeyAuthentication/g' \
         -e 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' \
         -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' \
         /etc/ssh/sshd_config
  display_success "SSH server configuration updated."

  display_info "Restarting SSH service..."
  sudo systemctl restart ssh
  display_success "SSH service restarted."
}

# Function to configure system settings
configure_system() {
  display_info "Updating system configuration: setting hostname to 'EuangeLion', updating /etc/hosts file, generating locale settings, and setting timezone to Asia/Hong_Kong."
  sudo hostnamectl set-hostname "EuangeLion"
  sudo sed -i 's/localhost/EuangeLion localhost/g' /etc/hosts
  if ! grep -q "en_US.UTF-8 UTF-8" /etc/locale.gen; then
    echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
    sudo locale-gen > /dev/null 2>&1
  fi
  sudo timedatectl set-timezone "Asia/Hong_Kong"
  display_success "System configuration updated."
}

# Function to setup the environment
setup_environment() {
  display_info "Setting up the environment..."

  install_package zsh curl

  display_info "Installing pip..."
  download_file "https://bootstrap.pypa.io/get-pip.py" "/tmp/get-pip.py"
  sudo python3 /tmp/get-pip.py > /dev/null 2>&1
  rm /tmp/get-pip.py
  display_success "Pip installed."

  display_info "Installing wakatime..."
  sudo pip3 install wakatime > /dev/null 2>&1
  display_success "Wakatime installed."

  display_info "Configuring Zsh..."
  curl -o ~/.zshrc https://s.repo.host/addons/zshrc > /dev/null 2>&1
  display_success "Zsh configured."

  display_info "Changing default shell..."
  sudo chsh -s $(command -v zsh) "$current_user"
  display_success "Default shell changed."

  display_success "Environment setup completed successfully."

  zsh
}

# Function to install BBR
install_bbr() {
  local setup=$1

  if [[ -f "/etc/debian_version" ]]; then
    if [[ "$setup" == "-s" ]]; then
      display_success "Enabling BBR..."
      echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf > /dev/null
      echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf > /dev/null
      sudo sysctl -p > /dev/null
      display_success "BBR enabled."
    else
      display_info "Downloading BBR kernel..."
      curl -o /tmp/linux-headers-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb https://s.repo.host/addons/linux-headers-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb
      curl -o /tmp/linux-image-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb https://s.repo.host/addons/linux-image-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb
      display_success "BBR kernel downloaded."

      display_info "Installing BBR kernel..."
      sudo apt install /tmp/linux-*-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb > /dev/null 2>&1
      display_success "BBR kernel installed."

      rm /tmp/linux-*-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb
    fi
  else
    display_error "Unsupported distribution. Unable to install BBR."
    return 1
  fi
}

# Function to install Docker
install_docker() {
  display_info "Installing Docker: checking if Docker is already installed, installing Docker if necessary, and granting Docker privileges to user '$current_user'."
  if command -v docker >/dev/null 2>&1; then
    display_info "Docker is already installed, skipping installation."
  else
    curl -sSL https://get.docker.com | sh > /dev/null 2>&1
    display_success "Docker installed."
  fi

  if [[ $current_user != "root" ]]; then
    display_info "Granting Docker privileges to user '$current_user'..."
    sudo usermod -aG docker "$current_user"
    display_success "Docker privileges granted to user '$current_user'."
  fi
}

# Function to reinstall Debian
reinstall_debian() {
  display_info "Installing Debian: using the specified mirror for installation."
  local mirror="http://deb.debian.org/debian"
  if [[ $(curl -s api.baka.cafe?isCN) == '1' ]]; then
    display_success "Region: \e[1mChina\e[0m, setting the system repo to \e[1mUSTC\e[0m."
    mirror="http://mirrors.ustc.edu.cn/debian"
  fi
  curl -sSL https://s.repo.host/addons/InstallNET.sh | sudo bash -s -- -d 12 -v 64 -a --mirror "$mirror" -p 'repo.host'
  display_success "Rebooting..."
}

# Function to install Caddy
install_caddy() {
  display_info "Installing Caddy..."

  install_package gnupg apt-transport-https lsb-release

  curl -sSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/caddy.gpg >/dev/null

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/caddy.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/caddy.list >/dev/null

  install_package caddy

  display_success "Caddy installed successfully."

  display_info "Please configure Caddy by editing the Caddyfile located at /etc/caddy/Caddyfile."
  display_info "For more information on configuring Caddy, refer to the official Caddy documentation."
}

declare -g current_user=$(whoami)

check_root_privileges

# Check the argument and execute the corresponding function
while [[ $# -gt 0 ]]; do
  case "$1" in
    "ssh-key")       configure_ssh_key;;
    "ssh")           configure_ssh;;
    "docker")        install_docker;;
    "system")        configure_system;;
    "environment")   setup_environment;;
    "reinstall")     reinstall_debian;;
    "bbr")
      if [[ -n "$2" ]]; then
        install_bbr "$2"
        shift
      else
        display_message error "Argument is required for 'bbr' command."
        exit 1
      fi
      ;;
    "caddy")         install_caddy;;
    "create-user")
      if [[ -n "$2" ]]; then
        create_user "$2" "$3"
        shift 2
      else
        display_message error "Username is required for 'create-user' command."
        exit 1
      fi
      ;;
    *)  
      display_message error "Invalid argument: $1."
      exit 1
      ;;
  esac
  shift
done