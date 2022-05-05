# PowerShell-Wsl-Alpine

Powershell cmdlet to quickly create a small Alpine based WSL distribution. It is
available in PowerShell Gallery as `Wsl-Alpine`.

## Rationale

As a developer working mainly on Linux, I have the tendency to put everything in
the same WSL distribution, ending up with a distribution containing Go, Python,
Terraform...

This module is here to reduce the cost of spawning a new distrbution for
development in order to have concerns more splitted. It is also a reminder of
the congfiguration steps to have a working distribution.

## What it does

This module provides a cmd called `Install-WslAlpine` that will install a
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
- zsh with oh-my-zsh is used as shell.
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
####> Downloading https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-minirootfs-3.15.0-x86_64.tar.gz â†’ C:\Users\AntoineMartin\AppData\Local\WslAlpine\rootfs.tar.gz...
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

## Development

To modify the module, clone it in your local modules directory:

```console
> cd $env:USERPROFILE\Documents\WindowsPowerShell\Modules\
> git clone https://github.com/antoinemartin/PowerShell-Wsl-Alpine Wsl-Alpine
```

## TODO

- [ ] Add a switch to avoid the configuration of the distribution.
- [ ] Document the customization of the distrbution.
- [ ] Add a command to export the current filesystem and use it as input for
      other distrbutions.
- [ ] Allow publication of the module through github actions.
- [ ] Publish the customized root filesystem to improve startup.
