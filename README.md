<!--
Copyright (c) 2025 Khipu HPC
Copyright (c) 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
in Cooperation with Max Planck Society
SPDX-License-Identifier: CC-BY-NC-SA-1.0
-->

# VS Code Remote for Khipu HPC

Scripts for connecting [VS Code](https://code.visualstudio.com/download) to a non-interactive Khipu compute 
node managed by [SLURM](https://slurm.schedmd.com/overview.html) workload manager. 

This repo has been forked from [esi-neuroscience/vscode-remote-hpc](https://github.com/esi-neuroscience/vscode-remote-hpc)
and was slightly modified to work with Khipu HPC cluster. It supports macOS, Linux and Windows (PowerShell) 
and does not need special privileges. 

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
irm https://raw.githubusercontent.com/khipu-utec/vscode-remote-hpc/refs/heads/main/client/setup.ps1 | iex
```

![](https://github.com/khipu-utec/vscode-remote-hpc/blob/main/doc/media/vscode_remote_khipu_demo_win.gif)

### Linux, macOS and Windows Subsystem for Linux (WSL)

Open a terminal (`Terminal.App` in macOS) and run the following command:

```zsh
curl -fsSL https://raw.githubusercontent.com/khipu-utec/vscode-remote-hpc/refs/heads/main/client/setup.sh | bash
```

![](https://github.com/khipu-utec/vscode-remote-hpc/blob/main/doc/media/vscode_remote_khipu_demo_linux.gif)

## Usage

The `vscode-remote-khipu` host is now available in the VS Code Remote Explorer. 
Connecting to this host will automatically launch a sbatch job to the data-science 
partition, wait for it to start, and connect to the node as soon as the job is running.
Thus, controlling VS Code remote HPC sessions can be done exclusively from 
within VS Code itself. 

Running jobs are automatically reused. If a running job is found, the script simply 
connects to it. You can safely open many remote windows and they will all share 
the same SLURM job. 

Note that disconnecting the remote session in VS Code will **not** kill the 
corresponding SLURM job. If you close the remote window the SLURM job keeps running. 
Jobs are automatically killed by the SLURM controller when they reach their 
runtime limit (4 hours). You can manually kill the job by logging on to the cluster head node 
and running the command 

``` bash
vscode-remote cancel
```

or manually by using `squeue --me` to find the right SLURM job id followed by 
`scancel <jobid>`. 

The `vscode-remote` command installed on your HPC offers some additional commands 
to list or cancel running jobs. You can invoke `vscode-remote help` for more information. 

## Removal

To remove `vscode-remote-khipu` either manually delete the "vscode-remote-khipu" 
config block from your ssh configuration file and remove the generated ssh 
key-pair (`vscode-remote-khipu` + `vscode-remote-khipu.pub`) or run the respective 
setup command again:

### Windows 10 and 11 (PowerShell) 

``` PowerShell
irm https://raw.githubusercontent.com/khipu-utec/vscode-remote-hpc/refs/heads/main/client/setup.ps1 | iex
```

### Linux, macOS and Windows Subsystem for Linux (WSL)

```zsh
curl -fsSL https://raw.githubusercontent.com/khipu-utec/vscode-remote-hpc/refs/heads/main/client/setup.sh | bash
```


