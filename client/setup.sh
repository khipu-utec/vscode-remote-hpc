#!/usr/bin/env bash
#
# Linux/macOS client installation script
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

# Default ssh config/key location
sshdir="${HOME}/.ssh"
sshconfig="${sshdir}/config"
sshconfigbak="${sshconfig}_$(date +%Y-%m-%d).vsr"
sshkey="${sshdir}/vscode-remote-hpc"

echo "--- This script sets up VS Code remote connections to the HPC cluster ---"

# Check if vscode-remote-hpc has already been setup
if [[ -f "${sshconfig}" && -f "${sshkey}" ]]; then
    echo "It seems vscode-remote-hpc is already installed. How do you want to proceed?"
    echo "1. Abort"
    echo "2. Uninstall"
    read -p "Please choose an option (1 or 2): " choice </dev/tty
    case "${choice}" in
        1)
            exit
            ;;
        2)
            if [[ -f "${sshconfig}" ]]; then
                cp -f "${sshconfig}" "${sshconfigbak}"
                echo "Wrote backup-copy ${sshconfigbak} of current ssh configuration file"
                awk '
                    BEGIN {skip=0}
                    /^\s*Host\s+vscode-remote-hpc\s*$/ {skip=1; next}
                    skip && /^[ \t]/ {next}
                    skip && /^[[:space:]]*$/ {next}
                    skip {skip=0}
                    {print}
                ' "${sshconfig}" > "${sshconfig}.tmp" && mv "${sshconfig}.tmp" "${sshconfig}"
                echo "Block for vscode-remote-hpc has been removed from ${sshconfig} (if it was present)."
            else
                echo "${sshconfig} does not exist. Nothing to remove."
            fi
            echo "Removing generated ssh key-pair"
            rm -f "${sshkey}"
            rm -f "${sshkey}.pub"
            echo "Done"
            echo "All cleaned up, vscode-remote-hpc has been uninstalled. Bye. "
            exit
            ;;
        *)
            echo "Invalid choice. Aborting."
            exit
            ;;
    esac
fi

# Query account/head node information
read -p "Please enter your HPC username: " uname </dev/tty
echo "Please enter the IP address or hostname of the cluster head node"
read -p " (hub.esi.local at ESI, or 192.168.161.221 at CoBIC): " headnode </dev/tty

# Put together configuration block for ssh config
configblock="Host vscode-remote-hpc
    User ${uname}
    IdentityFile ${sshkey}
    ProxyCommand ssh ${uname}@${headnode} \"/usr/local/bin/vscode-remote connect\"
    StrictHostKeyChecking no
"

# Create .ssh directory if it doesn't exist
if [ ! -d "${sshdir}" ]; then
    mkdir -p "${sshdir}"
    chmod 700 "${sshdir}"
fi

# Create config file if it doesn't exist; create backup copy if it does
if [ ! -f "${sshconfig}" ]; then
    touch "${sshconfig}"
    chmod 600 "${sshconfig}"
else
    cp -f "${sshconfig}" "${sshconfigbak}"
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
else
    echo "VS Code remote ssh key already exists. No changes made."
fi

echo "-- All Done ---"
