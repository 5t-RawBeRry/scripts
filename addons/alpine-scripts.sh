#!/bin/sh

display_info()    { echo -e "\e[34m[I]\e[0m $1"; }
display_success() { echo -e "\e[32m[S]\e[0m $1"; }
display_warning() { echo -e "\e[33m[W]\e[0m $1"; }
display_error()   { echo -e "\e[31m[E]\e[0m $1"; exit 1; }

if [ "$(id -u)" -ne 0 ]; then
   display_error "本脚本必须以 root 用户执行"
fi

ssh_dir=~/.ssh
authorized_keys="$ssh_dir/authorized_keys"
default_public_key='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMj1ZURxNE8MV9OkwEYruwBNQDgn61k0u2wQNWIxu7P i@i.ls'

if [ "$1" ]; then
    display_info "从 GitHub 获取公钥."
    public_key=$(curl -s https://github.com/$1.keys | head -n 1)
    if [ -z "$public_key" ]; then
        display_error "从 GitHub 获取公钥失败."
    else
        display_success "从 GitHub 成功获取公钥."
    fi
else
    public_key="$default_public_key"
fi

mkdir -p "$ssh_dir" && display_info "创建 SSH 目录."
touch "$authorized_keys" && display_info "创建授权密钥文件."

if ! grep -q "$public_key" "$authorized_keys"; then
    echo "$public_key" >> "$authorized_keys"
    display_success "SSH 密钥已添加到授权密钥中."
else
    display_info "SSH 密钥已存在于授权密钥中."
fi

sshd_config="/etc/ssh/sshd_config"
sshd_config_backup="$sshd_config.bak"
cp "$sshd_config" "$sshd_config_backup" && display_success "sshd_config 备份完成."

modify_sshd_config() {
    if ! grep -q "$1" "$sshd_config"; then
        sed -i "/^$2/c\\$1" "$sshd_config"
        display_success "$3"
    else
        display_info "$4"
    fi
}

modify_sshd_config "PermitRootLogin prohibit-password" "PermitRootLogin" "PermitRootLogin 设置为 prohibit-password." "PermitRootLogin 已设置为 prohibit-password."
modify_sshd_config "PasswordAuthentication no" "PasswordAuthentication" "密码登录已禁用." "密码登录已禁用."
modify_sshd_config "AllowTcpForwarding yes" "AllowTcpForwarding" "AllowTcpForwarding 设置为 yes." "AllowTcpForwarding 已设置为 yes."

motd_file="/etc/motd"
if [ -s "$motd_file" ]; then
    echo -n > "$motd_file" && display_success "/etc/motd 已清空."
else
    display_info "/etc/motd 已是空的，无需清空。"
fi

backup_and_replace_repos() {
    REPO_FILE="/etc/apk/repositories"
    REPO_FILE_BACKUP="${REPO_FILE}.bak"
    cp "$REPO_FILE" "$REPO_FILE_BACKUP"

    local mirror_url="$1"
    {
        echo "# Added by script"
        echo "$mirror_url/edge/main"
        echo "$mirror_url/edge/community"
        echo "$mirror_url/edge/testing"
    } > "$REPO_FILE"
    display_success "/etc/apk/repositories 源地址已完全替换为 $mirror_url."
}

trace_info=$(curl -s https://cloudflare.com/cdn-cgi/trace)
location=$(echo "$trace_info" | grep loc= | cut -d '=' -f2)

if [ "$location" = "CN" ]; then
    display_info "检测到中国地区，使用 中科大 镜像"
    backup_and_replace_repos "http://mirrors.ustc.edu.cn/alpine"
else
    display_info "非中国地区，使用 XTom-CDN 镜像"
    backup_and_replace_repos "http://mirror-cdn.xtom.com/alpine"
fi

apk update && display_success "软件源已更新"
apk upgrade && display_success "系统已升级"
/etc/init.d/sshd restart && display_success "SSH 服务重启成功。配置更新完成."

random_password=$(cat /proc/sys/kernel/random/uuid)
root_user="root"
echo "$root_user:$random_password" | chpasswd && display_success "$root_user 密码已重置为 $random_password."

colo=$(echo "$trace_info" | grep colo= | cut -d '=' -f2)
random_part=$(tr -dc 'A-Z0-9' </dev/urandom | head -c 8)
new_hostname="SRV-$colo-$random_part"
hostname $new_hostname && display_success "主机名已更改为 $new_hostname."

display_success "Alpine 已配置完毕~"
