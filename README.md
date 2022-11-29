# PowerShell-Wsl-Alpine

Powershell cmdlet to quickly create a small Alpine based WSL distribution. It is
available in PowerShell Gallery as
[`Wsl-Alpine`](https://www.powershellgallery.com/packages/Wsl-Alpine/1.1).

## Rationale

As a developer working mainly on Linux, I have the tendency to put everything in
the same WSL distribution, ending up with a distribution containing Go, Python,
Terraform...

This module is here to reduce the cost of spawning a new distrbution for
development in order to have concerns more splitted. It is also a reminder of
the congfiguration steps to have a working distribution.

## What it does

This module provides a cmdlet called `Install-WslAlpine` that will install a
lightweight Windows Subsystem for Linux (WSL) distribution based on Alpine
Linux.

This command performs the following operations:

- Create a Distribution directory,
- Download the Root Filesystem,
- Create the WSL distribution,
- Configure the WSL distribution.

The distribution is configured as follows:

- A user named `alpine` is set as the default user. The user as `doas` (BSD
  version of sudo used in Alpine) privileges.
- zsh with [oh-my-zsh](https://ohmyz.sh/) is used as shell.
- [powerlevel10k](https://github.com/romkatv/powerlevel10k) is set as the
  default oh-my-zsh theme.
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) plugin
  is installed.
- The
  [wsl2-ssh-pageant](https://github.com/antoinemartin/wsl2-ssh-pageant-oh-my-zsh-plugin)
  plugin is installed in orther to use the GPG keys private keys available at
  the Windows level (I'm using a Yubikey).

## Pre-requisites

WSL 2 needs to be installed and working. If you are on Windows 11, a simple
`wsl --install` should get you going.

To install this module, you need to be started with the
[PowerShell Gallery](https://docs.microsoft.com/en-us/powershell/scripting/gallery/getting-started?view=powershell-7.2).

The WSL distribution uses a fancy zsh theme called
[powerlevel10k](https://github.com/romkatv/powerlevel10k). To work properly in
the default configuration, you need a [Nerd Font](https://www.nerdfonts.com/).
My personal advice is to use `Ubuntu Mono NF` available via [scoop](scoop.sh) in
the nerds font bucket:

```console
> scoop bucket add nerd-fonts
> scoop install UbuntuMono-NF-Mono
```

The font name is then `'UbuntuMono NF'` (for vscode, Windows Terminal...).

## Getting started

Install the module with:

```console
> Install-Module -Name Wsl-Alpine
```

And then create a WSL distribution with:

```console
> Install-WslAlpine
####> Creating directory [C:\Users\AntoineMartin\AppData\Local\WslAlpine]...
####> Downloading https://dl-cdn.alpinelinux.org/alpine/v3.17/releases/x86_64/alpine-minirootfs-3.17.0-x86_64.tar.gz â†’ C:\Users\AntoineMartin\AppData\Local\WslAlpine\rootfs.tar.gz...
####> Creating distribution [WslAlpine]...
####> Running initialization script on distribution [WslAlpine]...
####> Done. Command to enter distribution: wsl -d WslAlpine
>
```

You can specify the name of the distribution:

```console
> Install-WslAlpine alpine2
...
```

To uninstall the distribution, just type:

```console
> Uninstall-WslAlpine alpine2
>
```

It will remove the distrbution and wipe the directory completely.

## Example: Creating a distribution hosting docker

You can create a distribution for building docker images. Fist install the
distribution:

```powershell
❯ install-WslAlpine docker
####> Creating directory [C:\Users\AntoineMartin\AppData\Local\docker]...
####> Downloading https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-minirootfs-3.15.0-x86_64.tar.gz â†’ C:\Users\AntoineMartin\AppData\Local\docker\rootfs.tar.gz...
####> Creating distribution [docker]...
####> Running initialization script on distribution [docker]...
####> Done. Command to enter distribution: wsl -d docker
❯
```

Then connect to it as root and install docker:

```bash
# Connect to the distribution
❯ wsl -d docker -u root
[powerlevel10k] fetching gitstatusd .. [ok]
# Add docker
❯ apk --update add docker
(1/13) Installing libseccomp (2.5.2-r0)
...
OK: 304 MiB in 103 packages
# Enabling OpenRC
❯ openrc default
 * Caching service dependencies ...         [ ok ]
# Start docker with OpenRC
❯ rc-update add docker default
 * service docker added to runlevel default
# Start OpenRC, and hence docker, on distribution startup
❯ cat >/etc/wsl.conf <<EOF
heredoc> [boot]
heredoc> command = /sbin/openrc default
heredoc> EOF
# Allow default user to run docker
❯ addgroup alpine docker
# Return to powershell
❯ exit
# Terminate distrbution
❯ wsl --terminate docker
# Start distribution and docker
❯ wsl -d docker docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Now, with this distribution, you can add the following alias to
`%USERPROFILE%\Documents\WindowsPowerShell\profile.ps1`:

```powershell
function RunDockerInWsl {
  wsl -d docker /usr/bin/docker $args
}
Set-Alias -Name docker -Value RunDockerInWsl
```

and run docker directly from powershell:

```powershell
❯ docker run --rm -it alpine:latest /bin/sh
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
df9b9388f04a: Pull complete
Digest: sha256:4edbd2beb5f78b1014028f4fbb99f3237d9561100b6881aabbf5acce2c4f9454
Status: Downloaded newer image for alpine:latest
/ #
```

You can save the distrbution root filesystem for reuse:

```powershell
❯ Export-WslAlpine docker -OutputFile $env:USERPROFILE\Downloads\docker.tar.gz
Distribution docker saved to C:\Users\AntoineMartin\Downloads\docker.tar.gz
```

And then recreate the distribution in the same state from the exported root
filesystem:

```powershell
❯ Uninstall-WslAlpine docker
❯ Install-WslAlpine docker -SkipConfigure -RootFSURL file://$env:USERPROFILE\Downloads\docker.tar.gz
####> Creating directory [C:\Users\AntoineMartin\AppData\Local\docker]...
####> Downloading file://C:\Users\AntoineMartin\Downloads\docker.tar.gz â†’ C:\Users\AntoineMartin\AppData\Local\docker\rootfs.tar.gz...
####> Creating distribution [docker]...
####> Done. Command to enter distribution: wsl -d docker
❯ wsl -d docker docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
❯
```

## Development

To modify the module, clone it in your local modules directory:

```console
> cd $env:USERPROFILE\Documents\WindowsPowerShell\Modules\
> git clone https://github.com/antoinemartin/PowerShell-Wsl-Alpine Wsl-Alpine
```

## TODO

- [x] Add a switch to avoid the configuration of the distribution.
- [x] Document the customization of the distrbution.
- [x] Add a command to export the current filesystem and use it as input for
      other distrbutions.
- [ ] Allow publication of the module through github actions.
- [ ] Publish the customized root filesystem to improve startup.
