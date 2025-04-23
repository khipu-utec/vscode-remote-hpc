#
# Windows PowerShell client installation script
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

Write-Output "--- This script sets up VS Code remote connections to the HPC cluster ---"

$uname = Read-Host "Please enter your HPC uname: "
$headnode = Read-Host "Please enter the IP address or hostname of the cluster head node (hub at ESI, or 192.168.161.221 at CoBIC): "

$sshdir = "$HOME\.ssh"
$sshconfig = "$sshdir\config"
$sshkey = "$sshdir\vscode-remote-hpc"
$configblock = @"
Host vscode-remote-hpc
    User $uname
    IdentityFile $sshkey
    ProxyCommand ssh $headnode ""/usr/local/bin/vscode-remote connect""
    StrictHostKeyChecking no
"@

# Create .ssh directory if it doesn't exist
if (-not (Test-Path -Path $sshdir)) {
    New-Item -ItemType Directory -Path $sshdir | Out-Null
}

# Create config file if it doesn't exist
if (-not (Test-Path -Path $sshconfig)) {
    New-Item -ItemType File -Path $sshconfig | Out-Null
}

# Check for existing Host block
$configText = Get-Content $sshconfig -Raw
if ($configContent -notmatch "Host vscode-remote-hpc\s") {
    Add-Content -Path $sshconfig -Value "`n$configblock"
    Write-Output "Updated ssh configuration"
} else {
    Write-Output "VS Code remote HPC configuration already exists. No changes made."
}

# If it does not exist already, create a new ssh key for vscode-remote-hpc
if (-not (Test-Path -Path $sshkey)) {
   $ans = Read-Host "About to create and upload an ssh key to $headnode. You will be prompted for your cluster password. Press any key to continue "
   ssh-keygen -f $sshkey -t ed25519 -N ""
   ssh-copy-id -i $sshkey $headnode
}

Write-Output "-- All Done ---"
