# Copyright 2022 Antoine Martin
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


if ($IsWindows) {
    $wslPath = "$env:windir\system32\wsl.exe"
    if (-not [System.Environment]::Is64BitProcess) {
        # Allow launching WSL from 32 bit powershell
        $wslPath = "$env:windir\sysnative\wsl.exe"
    }

}
else {
    # If running inside WSL, rely on wsl.exe being in the path.
    $wslPath = "wsl.exe"
}


$module_directory = ([System.IO.FileInfo]$MyInvocation.MyCommand.Path).DirectoryName


function Install-WslAlpine {
    <#
    .SYNOPSIS
        Installs and configure a minimal Alpine based WSL distribution.

    .DESCRIPTION
        This command performs the following operations:
        - Create a Distribution directory
        - Download the Root Filesystem.
        - Create the WSL distribution.
        - Configure the WSL distribution.

        The distribution is configured as follow:
        - A user named `alpine` is set as the default user.
        - zsh with oh-my-zsh is used as shell.
        - `powerlevel10k` is set as the default oh-my-zsh theme.
        - `zsh-autosuggestions` plugin is installed.

    .PARAMETER DistributionName
        The name of the distribution. If ommitted, will take WslAlpine by
        default.

    .PARAMETER RootFSURL
        URL of the root filesystem. By default, it will take the official 
        Alpine root filesystem.

    .PARAMETER BaseDirectory
        Base directory where to create the distribution directory. Equals to 
        $env:APPLOCALDATA (~\AppData\Local) by default.

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        Install-WslAlpine toto
    
    .LINK
        Unistall-WslAlpine
        https://github.com/romkatv/powerlevel10k
        https://github.com/zsh-users/zsh-autosuggestions
        https://github.com/antoinemartin/wsl2-ssh-pageant-oh-my-zsh-plugin

    .NOTES
        The command tries to be indempotent. It means that it will try not to
        do an operation that already has been done before.

    #>    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$DistributionName = "WslAlpine",
        [string]$RootFSURL = "https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-minirootfs-3.15.0-x86_64.tar.gz",
        [string]$BaseDirectory = $env:LOCALAPPDATA
    )


    # Where to install the distribution
    $distribution_dir = "$BaseDirectory\$DistributionName"

    # Create the directory
    If (!(test-path $distribution_dir)) {
        Write-Host "####> Creating directory [$distribution_dir]..."
        $null = New-Item -ItemType Directory -Force -Path $distribution_dir
    }
    else {
        Write-Host "####> Distribution directory [$distribution_dir] already exists."
    }

    $rootfs_file = "$distribution_dir\rootfs.tar.gz"

    # Donwload the root filesystem
    If (!(test-path $rootfs_file)) {
        Write-Host "####> Downloading $RootFSURL → $rootfs_file..."
        if ($PSCmdlet.ShouldProcess($rootfs_file, 'Download root fs')) {
            (New-Object Net.WebClient).DownloadFile($RootFSURL, $rootfs_file)
        }
    }
    else {
        Write-Host "####> Root FS already at [$rootfs_file]."
    }

    # Retrieve the distribution if it already exists
    $current_distribution = Get-ChildItem HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss |  Where-Object { $_.GetValue('DistributionName') -eq $DistributionName }

    If ($null -eq $current_distribution) {
        Write-Host "####> Creating distribution [$DistributionName]..."
        if ($PSCmdlet.ShouldProcess($DistributionName, 'Create distribution')) {
            &$wslPath --import $DistributionName $distribution_dir $rootfs_file | Write-Verbose
        }
    }
    else {
        Write-Host "####> Distribution [$DistributionName] already exists."
    }

    Write-Host "####> Running initialization script on distribution [$DistributionName]..."
    if ($PSCmdlet.ShouldProcess($DistributionName, 'Configure distribution')) {
        Copy-Item -Path "$module_directory\.p10k.zsh" -Destination "\\wsl$\$DistributionName\tmp\.p10k.zsh"
        Copy-Item -Path "$module_directory\configure.sh" -Destination "\\wsl$\$DistributionName\tmp\configure.sh"
        &$wslPath -d $DistributionName -u root /bin/sh /tmp/configure.sh 2>&1 | Write-Verbose

        Get-ChildItem HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss |  Where-Object { $_.GetValue('DistributionName') -eq $DistributionName } | Set-ItemProperty -Name DefaultUid -Value 1000
    }

    Write-Host "####> Done. Command to enter distribution: wsl -d $DistributionName"
    ## More Stuff ?
    # To import your publick keys and use the yubikey for signing.
    #  gpg --keyserver keys.openpgp.org --search antoine@mrtn.fr
}

function Uninstall-WslAlpine {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$DistributionName = "WslAlpine",
        [string]$BaseDirectory = $env:LOCALAPPDATA
    )

    # Retrieve the distribution if it already exists
    $current_distribution = Get-ChildItem HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss |  Where-Object { $_.GetValue('DistributionName') -eq $DistributionName }

    # Where to install the distribution
    $distribution_dir = "$BaseDirectory\$DistributionName"

    if ($null -eq $current_distribution) {
        Write-Error "Distribution $DistributionName doesn't exist !" -ErrorAction Stop
    }
    else {
        if ($PSCmdlet.ShouldProcess($DistributionName, 'Unregister distribution')) {
            Write-Verbose "Unregistering WSL distribution $DistributionName"
            &$wslPath --unregister $DistributionName 2>&1 | Write-Verbose 
        }
        Remove-Item -Path $distribution_dir -Recurse
    }

}

Export-ModuleMember Install-WslAlpine
Export-ModuleMember Uninstall-WslAlpine
