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
public_key='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMj1ZURxNE8MV9OkwEYruwBNQDgn61k0u2wQNWIxu7P i@i.ls'

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

# 清空 motd 文件
motd_file="/etc/motd"
if [ -s "$motd_file" ]; then
    echo -n > "$motd_file" && display_success "/etc/motd 已清空."
else
    display_info "/etc/motd 已是空的，无需清空。"
fi

REPO_FILE="/etc/apk/repositories"
REPO_FILE_BACKUP="${REPO_FILE}.bak"
cp "$REPO_FILE" "$REPO_FILE_BACKUP"
{
    echo "# Added by script"
    echo "http://mirror-cdn.xtom.com/alpine/edge/main"
    echo "http://mirror-cdn.xtom.com/alpine/edge/community"
    echo "http://mirror-cdn.xtom.com/alpine/edge/testing"
} > "$REPO_FILE"
display_success "/etc/apk/repositories 源地址已完全替换为 mirror-cdn.xtom.com."

apk update && display_success "软件源已更新"

apk upgrade && display_success "系统已升级"

/etc/init.d/sshd restart && display_success "SSH 服务重启成功。配置更新完成。"

random_password=$(cat /proc/sys/kernel/random/uuid)
root_user="root"
echo "$root_user:$random_password" | chpasswd && display_success "$root_user 密码已重置为 $random_password."

display_success "Alpine 已配置完毕~"

read -p "是否要重启系统？(y/n): " restart_option
if [ "$restart_option" = "y" ]; then
    reboot
elif [ "$restart_option" = "n" ]; then
    display_info "系统不会重启。"
else
    display_error "无效的选项。系统不会重启。"
fi
