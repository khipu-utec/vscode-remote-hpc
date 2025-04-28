#
# Windows PowerShell client installation script
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

# Default ssh config/key location
$sshdir = "$HOME\.ssh"
$sshconfig = "$sshdir\config"
$sshkey = "$sshdir\vscode-remote-hpc"

# Either query for HPC username and headnode or take CLI arguments
param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$uname,
    [Parameter(Position=1, Mandatory=$false)]
    [string]$headnode
)

Write-Output "--- This script sets up VS Code remote connections to the HPC cluster ---"

# Check if vscode-remote-hpc has already been setup
if ((Test-Path $sshconfig) -and (Test-Path $sshkey)) {
    if ($PSBoundParameters.Count -eq 0) {
        Write-Output "It seems vscode-remote-hpc is already installed. How do you want to proceed?"
        Write-Output "1. Abort"
        Write-Output "2. Uninstall"
        $choice = Read-Host "Please choose an option (1 or 2)"
    } else {
        $choice = '2'
    }
    switch ($choice) {
        '1' {
            exit
            }
        '2' {
            Write-Output "Removing vscode-remote-hpc ssh configuration entry"
            if (Test-Path $sshconfig) {
                sshconfigbak = "$sshconfig.bak"
                Copy-Item -Path "$sshconfig" -Destination "$sshconfigbak" -Force
                Write-Output "Wrote backup-copy $sshconfigbak of current ssh configuration file"
                $lines = Get-Content $sshconfig
                $newLines = @()
                $skipBlock = $false
                foreach ($line in $lines) {
                    # Detect start of block
                    if ($line -match '^\s*Host\s+vscode-remote-hpc\s*$') {
                        $skipBlock = $true
                        continue
                    }
                    # If skipping block, skip indented lines; stop skipping on next non-indented/non-empty line
                    if ($skipBlock) {
                        if ($line -match '^\s' -or $line -match '^\t') {
                            continue
                        } elseif ($line -match '^\s*$') {
                            continue  # Skip empty lines directly after block, cosmetic
                        } else {
                            $skipBlock = $false
                            # fall through and add this line, out of block
                        }
                    }
                    if (-not $skipBlock) {
                        $newLines += $line
                    }
                }
                $newLines | Set-Content $sshconfig
                Write-Output "Block for vscode-remote-hpc has been removed from $sshconfig (if it was present)."
            } else {
                Write-Output "$sshconfig does not exist. Nothing to remove."
            }
            Write-Output "Removing generated ssh key-pair"
            Remove-Item -Path "$sshkey" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$sshkey.pub" -Force -ErrorAction SilentlyContinue
            Write-Output "Done"
            Write-Output "All cleaned up, vscode-remote-hpc has been uninstalled. Bye. "
            return
        }
        Default {
            Write-Output "Invalid choice. Aborting."
            return
        }
    }
}

# Query account/head node information
if (-not $uname) {
    $uname = Read-Host "Please enter your HPC uname: "
}
if (-not $headnode) {
    Write-Output "Please enter the IP address or hostname of the cluster head node"
    $headnode = Read-Host "(hub.esi.local at ESI, or 192.168.161.221 at CoBIC): "
}

# Put together configuration block for ssh config
$configblock = @"
Host vscode-remote-hpc
    User $uname
    IdentityFile $sshkey
    ProxyCommand ssh $uname@$headnode ""/usr/local/bin/vscode-remote connect""
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
$configText = Select-String -Path $sshconfig -Pattern "Host vscode-remote-hpc"
if ($configText -eq $null){
    Add-Content -Path $sshconfig -Value "`n$configblock"
    Write-Output "Updated ssh configuration"
} else {
    Write-Output "VS Code remote HPC configuration already exists. No changes made."
}

# If it does not exist already, create a new ssh key for vscode-remote-hpc
if (-not (Test-Path -Path $sshkey)) {
   $ans = Read-Host "About to create and upload an ssh key to $headnode. You will be prompted for your cluster password. Press any key to continue "
   ssh-keygen -q -f $sshkey -t ed25519 -N '""'
   type "$sshkey.pub" | ssh $uname@$headnode "cat >> ~/.ssh/authorized_keys"
} else {
    Write-Output "VS Code remote ssh key already exists. No changes made."
}

Write-Output "-- All Done ---"
