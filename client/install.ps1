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
$configblock = @"
Host vscode-remote-hpc
    User $uname
    ProxyCommand ssh $headnode ""/usr/local/bin/vscode-remote.sh connect""
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
if ($configText -notmatch "(?ms)^Host\s+vscode-remote-hpc\b") {
    Add-Content -Path $sshconfig -Value "`n$configblock"
    Write-Output "Updated ssh configuration"
} else {
    Write-Output "VS Code remote HPC configuration already exists. No changes made."
}

Write-Output "-- All Done ---"
