# HPC Admin Setup

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
cd /opt/apps
git clone https://github.com/khipu-utec/vscode-remote-hpc.git
ln -s /opt/apps/vscode-remote-hpc/server/vscode-remote.sh /usr/local/bin/vscode-remote
ln -s /opt/apps/vscode-remote-hpc/server/vscode-remote-job.sh /usr/local/bin/vscode-remote-job.sh
```

Ensure that both scripts can be executed by non-privileged users. 