#!/usr/bin/env bash
#
# Linux/macOS client installation script
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

echo "--- This script sets up VS Code remote connections to the HPC cluster ---"

read -p "Please enter your HPC username: " uname
read -p "Please enter the IP address or hostname of the cluster head node (hub at ESI, or 192.168.161.221 at CoBIC): " headnode

sshdir="${HOME}/.ssh"
sshconfig="${sshdir}/config"
configblock="Host vscode-remote-cpu
    User ${uname}
    IdentityFile ~/.ssh/vscode-remote
    ProxyCommand ssh ${headnode} \"~/bin/vscode-remote\"
    StrictHostKeyChecking no
"

# Create .ssh directory if it doesn't exist
if [ ! -d "${sshdir}" ]; then
    mkdir -p "${sshdir}"
    chmod 700 "${sshdir}"
fi

# Create config file if it doesn't exist
if [ ! -f "${sshconfig}" ]; then
    touch "${sshconfig}"
    chmod 600 "${sshconfig}"
fi

# Check for existing Host block
if ! grep -qE '^[Hh]ost[[:space:]]+vscode-remote\b' "${sshconfig}"; then
    echo "" >> "${sshconfig}"
    echo "${configblock}" >> "${sshconfig}"
    echo "Updated ssh configuration"
else
    echo "VS Code remote configuration already exists. No changes made."
fi

echo "-- All Done ---"
