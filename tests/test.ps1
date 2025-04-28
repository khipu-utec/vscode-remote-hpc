#
# Tests performing Windows installations/removals
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

# Get correct path to setup script
$Testsdir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VSRsetup = Join-Path $Testsdir "..\here\add_vscode_host.ps1"
$VSRsetup = Resolve-Path $VSRsetup

# Test parameters (Set as appropriate)
$VSRtester = "testuser"
$VSRhead = "hpc-head.domain.local"

# Default ssh config/key location
$sshdir = "$HOME\.ssh"
$sshconfig = "$sshdir\config"
$sshkey = "$sshdir\vscode-remote-hpc"

# Prepare what the expected Host block added by vscode-remote-hpc should look like
$expectedconfig = @"
Host vscode-remote-hpc
    User $VSRtester
    IdentityFile $sshkey
    ProxyCommand ssh $VSRtester@$VSRhead ""~/bin/vscode-remote cpu""
    StrictHostKeyChecking no
"@.Trim()

# Run the main script w/input args to suppress interactive prompts
& $VSRsetup $VSRtester $VSRhead

# Read the actual file and regex to extract ssh configuration added by vscode-remote-hpc
$configblock = Get-Content $sshconfig -Raw
$match = [regex]::Match($configblock, "(^Host\s+vscode-remote-hpc.*?)(?:(?:^Host|\z))", [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($match.Success) {
    $actualconfig = $match.Groups[1].Value.Trim()
    if ($actualconfig -eq $expectedconfig) {
        Write-Host "Test passed: Host block written correctly." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Test failed: Host block content does not match expected." -ForegroundColor Red
        Write-Host "Expected:"
        Write-Host $expectedconfig
        Write-Host "Actual:"
        Write-Host $actualconfig
        exit 1
    }
} else {
    Write-Host "Test failed: Host block not found in config file." -ForegroundColor Red
    exit 1
}
