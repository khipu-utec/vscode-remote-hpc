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
$VSRsetup = Join-Path $Testsdir "..\client\setup.ps1"
$VSRsetup = Resolve-Path $VSRsetup

# Test parameters (set as appropriate)
$VSRtester = "testuser"
$VSRhead = "hpc-head.domain.local"

# Default ssh config/key location
$sshdir = "$HOME\.ssh"
$sshconfig = "$sshdir\config"
$sshconfigbak = "${sshconfig}_$(get-date -f yyyy-MM-dd).vsr"
$sshkey = "$sshdir\vscode-remote-hpc"
$dummykey = "$sshdir\dummy"

# Prepare what the expected Host block added by vscode-remote-hpc should look like
$expectedconfig = @"
Host vscode-remote-hpc
    User $VSRtester
    IdentityFile $sshkey
    ProxyCommand ssh $VSRtester@$VSRhead ""/usr/local/bin/vscode-remote connect""
    StrictHostKeyChecking no
"@.Trim()

# Check for existing ssh keys/config
if ((Test-Path -Path $sshkey) -or (Test-Path -Path "$sshkey.pub") (Test-Path -Path $sshconfig)) {
    Write-Host "Error: cannot run tests with existing ssh keys/config file" -ForegroundColor Red
    exit 1
}

# Run the setup w/input args to suppress interactive prompts
Write-Host "Installing vscode-remote-hpc"
& $VSRsetup $VSRtester $VSRhead

# First and foremost: ensure ssh config has been created
if (Test-Path -Path $sshconfig) {
    Write-Host "Test passed: ssh config file has been created" -ForegroundColor Green
} else {
    Write-Host "Test failed: ssh config file not found" -ForegroundColor Red
}

# Read the actual ssh config file and regex to extract ssh configuration added by vscode-remote-hpc
$configblock = Get-Content $sshconfig -Raw
$match = [regex]::Match($configblock, "(^Host\s+vscode-remote-hpc.*?)(?:(?:^Host|\z))", [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($match.Success) {
    $actualconfig = $match.Groups[1].Value.Trim()
    if ($actualconfig -eq $expectedconfig) {
        Write-Host "Test passed: Host block written correctly." -ForegroundColor Green
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

# Ensure ssh keys have been generated
if ((Test-Path -Path $sshkey) -and (Test-Path -Path "$sshkey.pub")) {
    Write-Host "Test passed: ssh keys generated." -ForegroundColor Green
} else {
    Write-Host "Test failed: ssh keys not found." -ForegroundColor Red
    exit 1
}

# Uninstall vscode-remote-hpc
Write-Host "Uninstalling vscode-remote-hpc"
& $VSRsetup $VSRtester $VSRhead

# Ensure ssh config file is still present
if (Test-Path -Path $sshconfig) {
    Write-Host "Test passed: ssh config file still present" -ForegroundColor Green
} else {
    Write-Host "Test failed: ssh config file has been removed" -ForegroundColor Red
}

# Ensure backup copy of ssh configuration has been created
if (Test-Path -Path $sshconfigbak) {
    Write-Host "Test passed: backup copy of ssh config generated." -ForegroundColor Green
} else {
    Write-Host "Test failed: backup copy of ssh config missing." -ForegroundColor Red
    exit 1
}

# Ensure vscode-remote-hpc config block has been wiped
$configblock = Get-Content $sshconfig -Raw
$match = [regex]::Match($configblock, "(^Host\s+vscode-remote-hpc.*?)(?:(?:^Host|\z))", [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $match.Success) {
    Write-Host "Test passed: Host block removed from config file." -ForegroundColor Green
} else {
    Write-Host "Test failed: Host block still present in config file." -ForegroundColor Red
    exit 1
}

# Ensure ssh keys have been removed
if ((Test-Path -Path $sshkey) -or (Test-Path -Path "$sshkey.pub")) {
    Write-Host "Test failed: ssh key pair still present." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Test passed: ssh keys have been removed." -ForegroundColor Green
}

# Manually create dummy ssh keys and config file entries
ssh-keygen -q -f $dummykey -t ed25519 -N '""'
$dummyblock = @"
Host VeryImportant
    User somebody
    IdentityFile $dummykey
"@
Add-Content -Path $sshconfig -Value "`n$dummyblock"

# Re-run the setup and ensure existing config + keys stay intact
Write-Host "Re-install vscode-remote-hpc with existing ssh config + keys"
& $VSRsetup $VSRtester $VSRhead

# Ensure backup copy of ssh configuration has been created
if (Test-Path -Path $sshconfigbak) {
    Write-Host "Test passed: backup copy of ssh config generated." -ForegroundColor Green
} else {
    Write-Host "Test failed: backup copy of ssh config missing." -ForegroundColor Red
    exit 1
}

# Ensure backup copy contains orig config
$backupconfigblock = Get-Content $sshconfigbak -Raw
$match = [regex]::Match($backupconfigblock, "(^Host\s+VeryImportant.*?)(?:(?:^Host|\z))", [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($match.Success) {
    $actualconfig = $match.Groups[1].Value.Trim()
    if ($actualconfig -eq $dummyblock) {
        Write-Host "Test passed: Original config preserved in backup config file." -ForegroundColor Green
    } else {
        Write-Host "Test failed: Original config not matched in backup config file." -ForegroundColor Red
        Write-Host "Expected:"
        Write-Host $dummyblock
        Write-Host "Actual:"
        Write-Host $actualconfig
        exit 1
    }
} else {
    Write-Host "Test failed: Host block not found in backup config file." -ForegroundColor Red
    exit 1
}

# Read the actual ssh config file and regex to extract ssh configuration added by vscode-remote-hpc
# Additionally, ensure existing config is still in place
$configblock = Get-Content $sshconfig -Raw
$match = [regex]::Match($configblock, "(^Host\s+vscode-remote-hpc.*?)(?:(?:^Host|\z))", [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($match.Success) {
    $actualconfig = $match.Groups[1].Value.Trim()
    if ($actualconfig -eq $expectedconfig) {
        Write-Host "Test passed: Host block written correctly." -ForegroundColor Green
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
$match = [regex]::Match($configblock, "(^Host\s+VeryImportant.*?)(?:(?:^Host|\z))", [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($match.Success) {
    $actualconfig = $match.Groups[1].Value.Trim()
    if ($actualconfig -eq $dummyblock) {
        Write-Host "Test passed: Existing ssh config has been preserved." -ForegroundColor Green
    } else {
        Write-Host "Test failed: Existing ssh config not found in $sshconfig." -ForegroundColor Red
        Write-Host "Expected:"
        Write-Host $dummyblock
        Write-Host "Actual:"
        Write-Host $actualconfig
        exit 1
    }
} else {
    Write-Host "Test failed: Host block not found in config file." -ForegroundColor Red
    exit 1
}

# Ensure vscode-remote-hpc ssh keys have been generated
if ((Test-Path -Path $sshkey) -and (Test-Path -Path "$sshkey.pub")) {
    Write-Host "Test passed: ssh keys generated." -ForegroundColor Green
} else {
    Write-Host "Test failed: ssh keys not found." -ForegroundColor Red
    exit 1
}

# Ensure existing ssh keys have been preserved
if ((Test-Path -Path $dummykey) -and (Test-Path -Path "$dummykey.pub")) {
    Write-Host "Test passed: Existing ssh keys have been preserved." -ForegroundColor Green
} else {
    Write-Host "Test failed: Existing ssh keys not found." -ForegroundColor Red
    exit 1
}

Write-Host "ALL PASSED"
