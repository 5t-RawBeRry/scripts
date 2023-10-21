# Debian System Configuration Script

For a quick overview in Chinese, check the [README.zh.md](./README.zh.md).

This BASH script serves as a collection of utilities for Debian systems designed to automate a variety of system configuration tasks remotely. These tasks range from security settings, performance optimizations, software installations, to system management tasks.

## **Key Features**

1. **SSH Key Configuration**: Set up the SSH key for secure remote access in a jiffy.
2. **SSH Server Tweaking**: Fine-tune the intricate settings of your SSH server.
3. **Docker Installation**: Equip your system with Docker for containerized applications.
4. **System Settings**: Update your system's hostname, locale, and timezone settings.
5. **Environment Setup**: Establish a user-friendly shell and development toolkit.
6. **Debian Reinstallation**: Conduct a clean reinstallation of Debian.
7. **BBR Installation**: Boost network performance with BBR.
8. **Caddy Web Server Installation**: Get Caddy web server up and running.
9. **User Creation with Sudo Privileges**: Quickly spin up a new user and allocate permissions.

## **Prerequisites**

- A system running Debian.
- Ensure you have sudo privileges or root access.
- An active internet connection, as the script fetches some files online.

## **Usage**

You don't need to directly download the script but can execute it remotely using the curl command. Here's the generic format to use the script:

```sh
curl -sSL https://s.repo.host/script.sh | bash -s -- <command> [options]
```

Where `<command>` and `[options]` vary depending on the specific task you wish to execute.

### **Available Commands**:

You can invoke the different functionalities of the script using the following commands:

- `ssh-key`
- `ssh`
- `docker`
- `system`
- `environment`
- `reinstall`
- `bbr`
- `caddy`
- `create-user`

For a detailed guide on how to use a specific command, use:

```sh
curl -sSL https://s.repo.host/script.sh | bash -s -- help <command>
```

This will display more in-depth information about utilizing the particular command.

## **Usage Examples**:

1. **Set up SSH key**:

    ```sh
    curl -sSL https://s.repo.host/script.sh | bash -s -- ssh-key
    ```

2. **Install Docker**:

    ```sh
    curl -sSL https://s.repo.host/script.sh | bash -s -- docker
    ```

3. **Create a new user**:

    ```sh
    curl -sSL https://s.repo.host/script.sh | bash -s -- create-user <username> <password>
    ```

    Replace `<username>` and `<password>` with the actual username and password you choose.

## **Cautions**:

- Ensure you back up crucial data before using system-level commands like `reinstall`.
- Never run scripts remotely without inspecting them first, as they could have profound impacts on your system.

## **License**

For the license terms and details regarding this script, please refer to [LICENSE.md](./LICENSE.md).

Before using this script, please make sure you fully understand its licensing conditions. It is the responsibility of each user to comply with relevant laws and terms. If you do not agree with or understand these terms, please do not use this script.

Prior to use, it is recommended that you thoroughly read and ensure you fully agree with its contents. This is to ensure that your usage complies with the requirements of the terms and to avoid any potential risks associated with illegal use or violation of the license terms.