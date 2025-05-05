#!/usr/bin/env bash
#
# Linux/macOS client installation script
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

# Either query for HPC username and headnode or take CLI arguments
# (mainly intended for testing!)
if [ -n "$1" ]; then
    uname="$1"
fi
if [ -n "$2" ]; then
    headnode="$2"
fi

# Default ssh config/key location
sshdir="${HOME}/.ssh"
sshconfig="${sshdir}/config"
sshconfigbak="${sshconfig}_$(date +%Y-%m-%d).vsr"
sshkey="${sshdir}/vscode-remote-hpc"

echo "--- This script sets up VS Code remote connections to the HPC cluster ---"

# Check if vscode-remote-hpc has already been setup
if [[ -f "${sshconfig}" && -f "${sshkey}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "It seems vscode-remote-hpc is already installed. How do you want to proceed?"
        echo "1. Abort"
        echo "2. Uninstall"
        read -p "Please choose an option (1 or 2): " choice </dev/tty
    else
        choice='2'
    fi
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
                   /^[ \t]*Host[ \t]+vscode-remote-hpc[ \t]*$/ {skip=1; next}
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
if [[ -z "${uname+x}" ]]; then
    read -p "Please enter your HPC username: " uname </dev/tty
fi
if [[ -z "${headnode+x}" ]]; then
    echo "Please enter the IP address or hostname of the cluster head node"
    read -p " (hub.esi.local at ESI, or 192.168.161.221 at CoBIC): " headnode </dev/tty
fi

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
    if [[ $# -eq 0 ]]; then
        read -p "About to create and upload an ssh key to ${headnode}. You will be prompted for your cluster password. Press any key to continue " ans </dev/tty
    fi
    machine="${HOST}"
    if [ -z "${machine}" ]; then
        machine="${HOSTNAME}"
    fi
    ssh-keygen -q -f "${sshkey}" -t ed25519 -C "vscode-remote-hpc@${machine}" -N ""
    if [[ $# -eq 0 ]]; then
        ssh-copy-id -i "${sshkey}" "${uname}@${headnode}"
    fi
else
    echo "VS Code remote ssh key already exists. No changes made."
fi

echo "-- All Done ---"
