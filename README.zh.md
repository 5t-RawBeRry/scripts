# 远程Debian系统配置脚本

这个BASH脚本是为Debian系统设计的一系列实用程序集合，用于远程自动化执行各种系统配置任务。这些功能包括安全设置、性能优化、软件安装和系统管理任务。

## 主要特点

1. **SSH密钥配置**：快速配置SSH密钥，以实现安全的远程访问。
2. **SSH服务器设置**：调整SSH服务器的细微设置。
3. **Docker安装**：为容器化应用程序安装Docker。
4. **系统设置**：更新系统的主机名、区域设置和时区设置。
5. **环境设置**：建立一个用户友好的Shell和开发工具。
6. **Debian重装**：执行Debian的干净重新安装。
7. **BBR安装**：使用BBR优化网络性能。
8. **Caddy Web服务器安装**：安装Caddy web服务器。
9. **创建具有sudo权限的用户**：快速创建新用户并分配权限。

## 使用前提

- 一台运行Debian的系统。
- 确保你拥有sudo权限或根访问权限。
- 可用的网络连接，因为脚本需要下载一些文件。

## 如何使用

你不需要直接下载脚本，而是可以使用curl命令远程执行。以下是使用脚本的一般格式：

```sh
curl -sSL https://s.repo.host/script.sh -o /tmp/script.sh && bash /tmp/script.sh <command> [options]
```

其中 `<command>` 和 `[options]` 根据你想要执行的特定任务而变化。

### 可用命令:

你可以用以下命令调用脚本的不同功能：

- `ssh-key`
- `ssh`
- `docker`
- `system`
- `environment`
- `reinstall`
- `bbr`
- `caddy`
- `create-user`

对于详细的命令使用说明，请使用：

```sh
curl -sSL https://s.repo.host/script.sh | bash -s -- help <command>
```

这将显示有关如何使用特定命令的更多详细信息。

## 使用示例:

1. **设置SSH密钥**:

    ```sh
    curl -sSL https://s.repo.host/script.sh | bash -s -- ssh-key
    ```

2. **安装Docker**:

    ```sh
    curl -sSL https://s.repo.host/script.sh | bash -s -- docker
    ```

3. **创建一个新用户**:

    ```sh
    curl -sSL https://s.repo.host/script.sh | bash -s -- create-user <username> <password>
    ```

    将 `<username>` 和 `<password>` 替换为你选择的实际用户名和密码。

## 注意事项:

- 在使用像 `reinstall` 这样的系统级命令之前，确保已备份重要数据。
- 永远不要在未经检查的情况下远程运行脚本，因为它们可能会对你的系统产生重大影响。

## 许可证

有关该脚本的许可条款和细节，请参阅 [LICENSE.md](./LICENSE.md)。

在使用此脚本前，请确保你已经充分理解了其许可条件。遵守相关法律和条款是每个用户的责任。如果你不同意或不理解这些条款，请不要使用此脚本。

使用前，建议详细阅读并确保你完全同意其内容。这是确保你的使用符合条款要求，避免因非法使用或违反许可条款而导致的任何潜在风险。