#!/bin/sh

display_info()    { echo -e "\e[34m[I]\e[0m $1"; }
display_success() { echo -e "\e[32m[S]\e[0m $1"; }
display_warning() { echo -e "\e[33m[W]\e[0m $1"; }
display_error()   { echo -e "\e[31m[E]\e[0m $1"; exit 1; }

if [[ $EUID -ne 0 ]]; then
   display_error "本脚本必须以 root 用户执行"
   exit 1
fi

ssh_dir=~/.ssh
authorized_keys="$ssh_dir/authorized_keys"
public_key='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMj1ZURxNE8MV9OkwEYruwBNQDgn61k0u2wQNWIxu7P i@i.ls'

if [ ! -d "$ssh_dir" ]; then
    mkdir -p "$ssh_dir" && display_info "创建 SSH 目录."
fi

if [ ! -f "$authorized_keys" ]; then
    touch "$authorized_keys" && display_info "创建授权密钥文件."
fi

if ! grep -q "$public_key" "$authorized_keys"; then
    echo "$public_key" >> "$authorized_keys"
    display_success "SSH 密钥已添加到授权密钥中."
else
    display_info "SSH 密钥已存在于授权密钥中."
fi

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak && display_success "sshd_config 备份完成."

if ! grep -q "^PermitRootLogin prohibit-password" /etc/ssh/sshd_config; then
    sed -i '/^PermitRootLogin/c\PermitRootLogin prohibit-password' /etc/ssh/sshd_config
    display_success "PermitRootLogin 设置为 prohibit-password."
else
    display_info "PermitRootLogin 已设置为 prohibit-password."
fi

if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    sed -i '/^PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config
    display_success "密码登录已禁用."
else
    display_info "密码登录已禁用."
fi

if ! grep -q "^AllowTcpForwarding yes" /etc/ssh/sshd_config; then
    sed -i '/^AllowTcpForwarding/c\AllowTcpForwarding yes' /etc/ssh/sshd_config
    display_success "AllowTcpForwarding 设置为 yes."
else
    display_info "AllowTcpForwarding 已设置为 yes."
fi

if [ -s /etc/motd ]; then
    echo -n > /etc/motd && display_success "/etc/motd 已清空."
else
    display_info "/etc/motd 已是空的，无需清空。"
fi

if ! grep -q "mirror-cdn.xtom.com/alpine/edge/testing" /etc/apk/repositories; then
    echo "http://mirror-cdn.xtom.com/alpine/edge/testing" >> /etc/apk/repositories
    sed -i 's/dl-cdn.alpinelinux.org/mirror-cdn.xtom.com/g' /etc/apk/repositories && display_success "/etc/apk/repositories 已更新."
    apk update && display_success "软件源已更新"
else
    display_info "/etc/apk/repositories 已包含所需源"
    apk update && display_success "软件源已更新"
fi

/etc/init.d/sshd restart && display_success "SSH 服务重启成功。配置更新完成。"

display_success "Alpine 已配置完毕~"
