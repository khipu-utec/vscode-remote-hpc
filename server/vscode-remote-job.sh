#!/bin/bash
#
# Stub for launching sshd via sbatch
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
# Copyright © 2025  Gert Mertes
#
# SPDX-License-Identifier: MIT
#
#SBATCH -o none

if [ ! -d "${HOME:-~}.ssh" ]; then
    mkdir -p ${HOME:-~}/.ssh
fi

if [ ! -f "${HOME:-~}/.ssh/vscode-remote-hostkey" ]; then
    ssh-keygen -t ed25519 -f ${HOME:-~}/.ssh/vscode-remote-hostkey -N ""
fi

if [ -f "/usr/sbin/sshd" ]; then
    sshd_cmd=/usr/sbin/sshd
else
    sshd_cmd=sshd
fi

$sshd_cmd -D -p $1 -f /dev/null -h ${HOME:-~}/.ssh/vscode-remote-hostkey
