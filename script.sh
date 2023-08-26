#!/bin/bash

# Function to display an informational message
display_info() {
  echo -e "\e[34m[I]\e[0m $1"
}

# Function to display a success message
display_success() {
  echo -e "\e[32m[S]\e[0m $1"
}

# Function to display an error message
display_error() {
  echo -e "\e[31m[E]\e[0m $1"
}

# Function to check if the script is running with root privileges
check_root_privileges() {
  if [[ $EUID -ne 0 ]]; then
    if sudo -v; then
      display_success "Sudo privileges granted."
    else
      display_error "Failed to obtain sudo privileges."
      exit 1
    fi
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    display_info "Installing sudo..."
    if [[ -f "/etc/debian_version" ]]; then
      apt update > /dev/null 2>&1
      apt install -y sudo > /dev/null 2>&1
    elif [[ -f "/etc/redhat-release" ]]; then
      yum install -y sudo > /dev/null 2>&1
    elif [[ -f "/etc/arch-release" ]]; then
      pacman -Syu --noconfirm sudo > /dev/null 2>&1
    else
      display_error "Unsupported distribution. Please install sudo manually."
      exit 1
    fi

    if ! command -v sudo >/dev/null 2>&1; then
      display_error "Failed to install sudo. Please install sudo manually."
      exit 1
    fi

    display_success "sudo installed successfully."
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


# Function to configure SSH server
configure_ssh() {
  display_info "Updating SSH server configuration..."
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
  display_info "Updating system configuration..."
  sudo hostnamectl set-hostname EuangeLion
  sudo sed -i 's/localhost/EuangeLion localhost/g' /etc/hosts
  sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  sudo locale-gen  > /dev/null 2>&1
  sudo timedatectl set-timezone Asia/Hong_Kong
  display_success "System configuration updated."
}

install_packages_apt() {
  sudo apt update > /dev/null 2>&1
  display_success "APT package lists updated."

  display_info "Installing required packages..."
  sudo apt install -y zsh python3-pip git curl > /dev/null 2>&1
  display_success "Packages installed."
}

# Function to install packages using Pacman
install_packages_pacman() {
  sudo pacman -Syu --noconfirm zsh python-pip git curl > /dev/null 2>&1
  display_success "Packages installed."
}

# Function to install packages using Yum
install_packages_yum() {
  sudo yum update -y > /dev/null 2>&1
  display_success "Yum package lists updated."

  display_info "Installing required packages..."
  sudo yum install -y zsh python3-pip git curl > /dev/null 2>&1
  display_success "Packages installed."
}

# Function to setup the environment
setup_environment() {
  display_info "Setting up the environment..."
  
  if [[ -f "/etc/debian_version" ]]; then
    install_packages_apt
  elif [[ -f "/etc/arch-release" ]]; then
    install_packages_pacman
  elif [[ -f "/etc/redhat-release" ]]; then
    install_packages_yum
  else
    display_error "Unsupported distribution. Unable to set up the environment."
    exit 1
  fi
  
  display_info "Installing pip..."
  sudo pip install pip==22.3.1 --break-system-packages > /dev/null 2>&1
  display_success "Pip installed."
  
  display_info "Installing wakatime..."
  pip3 install wakatime > /dev/null 2>&1
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

install_bbr() {
  local setup=$1

  if [[ -f "/etc/debian_version" ]]; then
    if [[ "$setup" == "-s" ]]; then
      echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
      echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
      sysctl -p
    else
      display_info "Downloading BBR kernel..."
      curl -o /tmp/linux-headers-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb https://s.repo.host/addons/linux-headers-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb
      curl -o /tmp/linux-image-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb https://s.repo.host/addons/linux-image-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb
      display_success "BBR kernel downloaded."

      display_info "Installing BBR kernel..."
      sudo apt install /tmp/linux-*-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb
      display_success "BBR kernel installed."

      rm /tmp/linux-*-6.4.0-m00nf4ce_6.4.0-g6e321d1c986a-1_amd64.deb
    fi
  else
    display_error "Unsupported distribution. Unable to set up the environment."
    exit 1
  fi

}

install_docker() {
  display_info "Installing docker..."
  if command -v docker >/dev/null 2>&1; then
    display_info "Docker is installed, skip it."
  else
    curl -sSL https://get.docker.com | sh  > /dev/null 2>&1
    display_success "Docker installed."
  fi
  if [[  $current_user != "root" ]]; then
    display_info "Granting docker privileges to user '$current_user'..."
    sudo usermod -aG docker "$current_user"
    display_success "Docker privileges granted to user '$current_user'."
  fi
}

reinstall_debian() {
  display_info "Installing debian..."
  if [[  `curl -s api.baka.cafe?isCN` == '1' ]]; then
    display_success "Region: \e[1mChina\e[0m, set the system repo to \e[1mUSTC\e[0m."
    curl -sSL https://s.repo.host/addons/InstallNET.sh | sudo bash -s -- -d 12 -v 64 -a --mirror 'http://mirrors.ustc.edu.cn/debian'
  else
    curl -sSL https://s.repo.host/addons/InstallNET.sh | sudo bash -s -- -d 12 -v 64 -a -p 'Kilin111'
    #display_error "No CN"
  fi
  display_success "Rebooting..."
}



declare -g current_user=$(whoami)

check_root_privileges

# Check the argument and execute the corresponding function
case "$1" in
  "ssh-key")
    configure_ssh_key
    ;;
  "ssh")
    configure_ssh
    ;;
  "docker")
    install_docker
    ;;
  "system")
    configure_system
    ;;
  "environment")
    setup_environment
    ;;
  "reinstall")
    reinstall_debian
    ;;
  "bbr")
    install_bbr "$2"
    ;;
  "create-user")
    if [[ -n "$2" ]]; then
      create_user "$2" "$3"
    else
      display_error "Username is required. Usage: ./script.sh create-user <username> [password]"
      exit 1
    fi
    ;;
  *)
    display_error "Invalid argument. Please specify one of the following: \e[1mssh-key, ssh, docker, system, environment, reinstall, create-user\e[0m"
    exit 1
    ;;
esac

