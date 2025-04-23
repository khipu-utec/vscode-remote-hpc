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

read -p "Please enter your HPC username: " uname </dev/tty
read -p "Please enter the IP address or hostname of the cluster head node (hub at ESI, or 192.168.161.221 at CoBIC): " headnode </dev/tty

sshdir="${HOME}/.ssh"
sshconfig="${sshdir}/config"
sshkey="${sshdir}/vscode-remote-hpc"
configblock="Host vscode-remote-hpc
    User ${uname}
    IdentityFile ${sshkey}
    ProxyCommand ssh ${headnode} \"/usr/local/bin/vscode-remote connect\"
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
if ! grep -qE '^[Hh]ost[[:space:]]+vscode-remote-hpc\b' "${sshconfig}"; then
    echo "" >> "${sshconfig}"
    echo "${configblock}" >> "${sshconfig}"
    echo "Updated ssh configuration"
else
    echo "VS Code remote HPC configuration already exists. No changes made."
fi

# If it does not exist already, create a new ssh key for vscode-remote-hpc
if [ ! -f "${sshkey}" ]; then
    read -p "About to create and upload an ssh key to ${headnode}. You will be prompted for your cluster password. Press any key to continue " ans </dev/tty
    ssh-keygen -q -f "${sshkey}" -t ed25519 -N ""
    ssh-copy-id -i "${sshkey}" "${headnode}"
fi

echo "-- All Done ---"
