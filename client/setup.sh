#!/usr/bin/env bash
#
# Linux/macOS client installation script
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

set -e

# Keep it simple in case we're running in a POSIX-shell
posix_abort() {
  printf "ERROR: %s\n" "$@" >&2
  exit 1
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
# shellcheck disable=SC2292
if [ -z "${BASH_VERSION:-}" ]
then
  posix_abort "Bash is required to interpret this script."
fi

# Default ssh config/key location
sshdir="${HOME}/.ssh"
sshconfig="${sshdir}/config"
sshconfigbak="${sshconfig}_$(date +%Y-%m-%d).vsr"
sshkey="${sshdir}/vscode-remote-hpc"

# Either query for HPC username and headnode or take CLI arguments
# (mainly intended for testing!)
if [ -n "$1" ]; then
    uname="$1"
fi
if [ -n "$2" ]; then
    headnode="$2"
fi

# String formatters to prettify output
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_blue="$(tty_mkbold 34)"
tty_green="$(tty_mkbold 32)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join()
{
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp()
{
  printf "%s" "${1/"$'\n'"/}"
}

announce()
{
  printf "${tty_green}>>> %s <<<${tty_reset}\n" "$(shell_join "$@")"
}

info()
{
  printf "${tty_blue}%s${tty_reset}\n" "$(shell_join "$@")"
}

error()
{
  printf "${tty_red}FAILED:${tty_bold} %s${tty_reset}\n" "$(chomp "$1")"
}

# Ensure errors are communicated properly
on_exit() {
    if [ $? -ne 0 ]; then
        error "Setup encountered an error. Examine previous error messages for details"
        cleanup
        exit 1
    fi
    info "Bye"
}
trap 'on_exit 2> /dev/null' SIGHUP SIGTERM SIGKILL EXIT

cleanup(){
    if [[ -f "${sshconfig}" ]]; then
        cp -f "${sshconfig}" "${sshconfigbak}"
        info "Wrote backup-copy ${sshconfigbak} of current ssh configuration file"
        awk '
           BEGIN {skip=0}
           /^[ \t]*Host[ \t]+vscode-remote-hpc[ \t]*$/ {skip=1; next}
           skip && /^[ \t]/ {next}
           skip && /^[[:space:]]*$/ {next}
           skip {skip=0}
           {print}
        ' "${sshconfig}" > "${sshconfig}.tmp" && mv "${sshconfig}.tmp" "${sshconfig}"
        info "Block for vscode-remote-hpc has been removed from ${sshconfig} (if it was present)."
    else
        info "${sshconfig} does not exist. Nothing to remove."
    fi
    info "Removing generated ssh key-pair"
    rm -f "${sshkey}"
    rm -f "${sshkey}.pub"
    info "Done"
}

# ----------------------------------------------------------------------
#                    START OF INSTALLATION SCRIPT
# ----------------------------------------------------------------------
announce "This script sets up VS Code remote connections to the HPC cluster"

# Check if vscode-remote-hpc has already been setup
if [[ -f "${sshconfig}" && -f "${sshkey}" ]]; then
    if [[ $# -eq 0 ]]; then
        info "It seems vscode-remote-hpc is already installed. How do you want to proceed?"
        info "1. Abort"
        info "2. Uninstall"
        read -p "Please choose an option (1 or 2): " choice </dev/tty
    else
        choice='2'
    fi
    case "${choice}" in
        1)
            exit
            ;;
        2)
            cleanup
            announce "All cleaned up, vscode-remote-hpc has been uninstalled."
            exit
            ;;
        *)
            error "Invalid choice. Aborting."
            exit
            ;;
    esac
fi

# Query account/head node information
if [[ -z "${uname+x}" ]]; then
    read -p "Please enter your HPC username: " uname </dev/tty
fi
if [[ -z "${headnode+x}" ]]; then
    info "Please enter the IP address or hostname of the cluster head node"
    read -p "(hub.esi.local at ESI, or 192.168.161.221 at CoBIC): " headnode </dev/tty
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
    info "Updated ssh configuration"
else
    info "VS Code remote HPC configuration already exists. No changes made."
fi

# If it does not exist already, create a new ssh key for vscode-remote-hpc
if [ ! -f "${sshkey}" ]; then
    if [[ $# -eq 0 ]]; then
        info "About to create and upload an ssh key to ${headnode}"
        info "You will be prompted for your cluster password."
        read -p "Press any key to continue " ans </dev/tty
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
    info "VS Code remote ssh key already exists. No changes made."
fi

announce "All Done"
