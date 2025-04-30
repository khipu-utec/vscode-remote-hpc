<!--
Copyright (c) 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
in Cooperation with Max Planck Society
SPDX-License-Identifier: CC-BY-NC-SA-1.0
-->

[![Test Setup](https://github.com/esi-neuroscience/vscode-remote-hpc/actions/workflows/test-setup.yml/badge.svg)](https://github.com/esi-neuroscience/vscode-remote-hpc/actions/workflows/test-setup.yml)
[![REUSE status](https://api.reuse.software/badge/github.com/esi-neuroscience/vscode-remote-hpc)](https://api.reuse.software/info/github.com/esi-neuroscience/vscode-remote-hpc)

# VS Code Remote HPC

Scripts for connecting [VS Code](https://code.visualstudio.com/download) to a 
non-interactive HPC compute node managed by the [SLURM](https://slurm.schedmd.com/overview.html)
workload manager. 

This repo has been forked from [vscode-remote-hpc](https://github.com/gmertes/vscode-remote-hpc)
and (in parts) heavily modified: the server-side installation requires administrative 
access to the cluster head node(s), the client side installation supports macOS, 
Linux and Windows (PowerShell) and does not need special privileges. 

## Features

This script is designed to be used with the [Remote- SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) 
extension for Visual Studio Code. 

- Automatically starts a batch job, or reuses an existing one, for VS Code to connect to.
- No need to manually execute the script on the HPC, just connect from the remote 
  explorer and the script handles everything automagically using an ssh `ProxyCommand`.

## Installation 

### Windows 10 and 11 (PowerShell) 

Open PowerShell and run the following command 

``` PowerShell
irm https://raw.githubusercontent.com/esi-neuroscience/vscode-remote-hpc/refs/heads/main/client/setup.ps1 | iex
```

### Linux, macOS and Windows Subsystem for Linux (WSL)

Open a terminal (`Terminal.App` in macOS) and run the following command:

```zsh
curl -fsSL https://raw.githubusercontent.com/esi-neuroscience/vscode-remote-hpc/refs/heads/main/client/setup.sh | bash
```

## Usage

![](https://github.com/esi-neuroscience/vscode-remote-hpc/blob/main/doc/media/vscode_remote_hpc_demo.gif)

The `vscode-remote-hpc` host is now available in the VS Code Remote Explorer. 
Connecting to this host will automatically launch a sbatch job on a HPC compute node, 
wait for it to start, and connect to the node as soon as the job is running.
Thus, controlling VS Code remote HPC sessions can be done exclusively from 
within VS Code itself. 

Running jobs are automatically reused. If a running job is found, the script simply 
connects to it. You can safely open many remote windows and they will all share 
the same SLURM job. 

Note that disconnecting the remote session in VS Code will **not** kill the 
corresponding SLURM job. If you close the remote window the SLURM job keeps running. 
Jobs are automatically killed by the SLURM controller when they reach their 
runtime limit. You can manually kill the job by logging on to the cluster head node 
and running the command 

``` bash
vscode-remote cancel
```

or manually by using `squeue --me` to find the right SLURM job id followed by 
`scancel <jobid>`. 

The `vscode-remote` command installed on your HPC offers some additional commands 
to list or cancel running jobs. You can invoke `vscode-remote help` for more information. 

## Removal

To remove `vscode-remote-hpc` either manually delete the "vscode-remote-hpc" 
config block from your ssh configuration file and remove the generated ssh 
key-pair (`vscode-remote-hpc` + `vscode-remote-hpc.pub`) or run the respective 
setup command again:

### Windows 10 and 11 (PowerShell) 

``` PowerShell
irm https://raw.githubusercontent.com/esi-neuroscience/vscode-remote-hpc/refs/heads/main/client/setup.ps1 | iex
```

### Linux, macOS and Windows Subsystem for Linux (WSL)

```zsh
curl -fsSL https://raw.githubusercontent.com/esi-neuroscience/vscode-remote-hpc/refs/heads/main/client/setup.sh | bash
```

## HPC Admin Setup

The following applications must be executable for non-privileged users on on all 
compute nodes:

- `sshd` installed in `/usr/sbin` or available in the `$PATH`
- `nc` (netcat) must be available on the login node(s)
- compute node names must resolve to their internal IP addresses
- compute nodes must be accessible via IP from the login node

The client-side setup expects `vscode-remote` as well as `vscode-remote-job.sh`
to reside in `/usr/local/bin`. The recommended manner to set it up that way is 
to clone this repository and use symlinks (so that future updates can be deployed
using a simple `git pull`):

``` bash
cd /path/to/cluter-fs/
git clone https://github.com/pantaray/vscode-remote-hpc.git
ln -s /path/to/cluter-fs/vscode-remote-hpc/server/vscode-remote.sh /usr/local/bin/vscode-remote
ln -s /path/to/cluter-fs/vscode-remote-hpc/server/vscode-remote-job.sh /usr/local/bin/vscode-remote-job.sh
```

Ensure that both scripts can be executed by non-privileged users. 
