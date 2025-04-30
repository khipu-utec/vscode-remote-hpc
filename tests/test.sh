#!/usr/bin/env bash
#
# Tests performing macOS/Linux installations/removals
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

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

# ----------------------------------------------------------------------
#   PREPARE STDOUT
# ----------------------------------------------------------------------

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

passed()
{
  printf "${tty_green}PASSED: ${tty_reset}%s\n" "$(shell_join "$@")"
}

info()
{
  printf "${tty_blue}===${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

error()
{
  printf "${tty_red}FAILED:${tty_bold} %s${tty_reset}\n" "$(chomp "$1")"
}

# Get correct path to setup script
testsdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSRsetup="$testsdir/../client/setup.sh"  # Assume .sh equivalent
VSRsetup="$(realpath "$VSRsetup")"

# Test parameters (set as appropriate)
VSRtester="testuser"
VSRhead="hpc-head.domain.local"

# Default ssh config/key location
sshdir="${HOME}/.ssh"
sshconfig="${sshdir}/config"
sshconfigbak="${sshconfig}_$(date +%Y-%m-%d).vsr"
sshkey="${sshdir}/vscode-remote-hpc"
dummykey="${sshdir}/dummy"

# Prepare what the expected Host block added by vscode-remote-hpc should look like
read -r -d '' expectedconfig <<EOF
Host vscode-remote-hpc
    User ${VSRtester}
    IdentityFile ${sshkey}
    ProxyCommand ssh ${VSRtester}@${VSRhead} "/usr/local/bin/vscode-remote connect"
    StrictHostKeyChecking no
EOF

# Check for existing ssh keys/config
if [ -f "${sshkey}" ] || [ -f "${sshkey}.pub" ] || [ -f "${sshconfig}" ]; then
    error "Cannot run tests with existing ssh keys/config file"
    exit 1
fi

# Run the setup w/input args to suppress interactive prompts
info "Installing vscode-remote-hpc"
"${VSRsetup}" "${VSRtester}" "${VSRhead}"

# Ensure ssh config has been created
if [ -f "${sshconfig}" ]; then
    passed "ssh config file has been created"
else
    error "ssh config file not found"
    exit 1
fi

# Function: extract a host block by name from $1 file
get_host_block() {
  # $1 = block name, $2 = file
  awk -v block="$1" '
    # Match start of the requested host block
    ($1 == "Host" && $2 == block) {inblock=1; print $0; next}
    # If in the right block and the line starts with Host (new block) and not the same block: stop
    (inblock && $1 == "Host" && $2 != block) {inblock=0}
    # Print all lines while in the block
    inblock {print $0}
  ' "$2" | sed '/^[[:space:]]*$/d'
}
# Compare actual config to expected
actualconfig=$(get_host_block "vscode-remote-hpc" "${sshconfig}")
if [ "${actualconfig}" == "${expectedconfig}" ]; then
    passed "Host block written correctly to ${sshconfig}"
else
    error "Host block content in ${sshconfig} does not match expected content"
    error "Expected:"
    error "${expectedconfig}"
    error "Actual:"
    error "${actualconfig}"
    exit 1
fi

# Ensure ssh keys have been generated
if [ -f "${sshkey}" ] && [ -f "${sshkey}.pub" ]; then
    passed "ssh keys succesfully generated"
else
    error "ssh keys not found"
    exit 1
fi

# Uninstall vscode-remote-hpc
info "Uninstalling vscode-remote-hpc"
"${VSRsetup}" "${VSRtester}" "${VSRhead}"

# Ensure ssh config file is still present
if [ -f "${sshconfig}" ]; then
    passed "ssh config ${sshconfig} file still present"
else
    error "ssh config file has been removed"
    exit 1
fi

# Ensure backup copy of ssh configuration has been created
if [ -f "${sshconfigbak}" ]; then
    passed "Backup copy ${sshconfigbak} of ssh config generated"
else
    error "Backup copy of ssh config missing"
    exit 1
fi

# Ensure Host block has been wiped
actualconfig=$(get_host_block "vscode-remote-hpc" "${sshconfig}")
if [ -z "$actualconfig" ]; then
    passed "Host block removed from config file ${sshconfig}"
else
    error "Host block still present in config file ${sshconfig}"
    exit 1
fi

# Ensure ssh keys have been removed
if [ -e "${sshkey}" ] || [ -e "${sshkey}.pub" ]; then
    error "ssh key pair still present"
    exit 1
else
    passed "ssh keys have been removed"
fi

# Manually create dummy ssh keys and config file entries
ssh-keygen -q -f "${dummykey}" -t ed25519 -N ""
read -r -d '' dummyblock <<EOF
Host VeryImportant
    User somebody
    IdentityFile ${dummykey}
EOF
echo "" >> "${sshconfig}"
echo "${dummyblock}" >> "${sshconfig}"

# Re-run the setup and ensure existing config + keys stay intact
info "Re-install vscode-remote-hpc with existing ssh config + keys"
"${VSRsetup}" "${VSRtester}" "${VSRhead}"

# Ensure backup copy of ssh configuration has been created
if [ -f "${sshconfigbak}" ]; then
    passed "Backup copy ${sshconfigbak} of ssh config generated"
else
    error "Backup copy of ssh config missing"
    exit 1
fi

# Ensure backup copy contains orig config
actualconfig=$(get_host_block "VeryImportant" "${sshconfigbak}")
# Remove leading/trailing whitespace:
actualconfig="$(echo "${actualconfig}" | sed 's/^[ \t]*//;s/[ \t]*$//')"
db_trim="$(echo "${dummyblock}" | sed 's/^[ \t]*//;s/[ \t]*$//')"
if [ "${actualconfig}" == "${db_trim}" ]; then
    passed "Original ssh config preserved in backup config file ${sshconfigbak}"
else
    error "Original ssh config not matched in backup config file ${sshconfigbak}"
    error "Expected:"
    error "${dummyblock}"
    error "Actual:"
    error "${actualconfig}"
    exit 1
fi

# Ensure vscode-remote-hpc host block is present
actualconfig=$(get_host_block "vscode-remote-hpc" "${sshconfig}")
if [ "${actualconfig}" == "${expectedconfig}" ]; then
    passed "Host block written correctly to ${sshconfig}"
else
    error "Host block content does not match expected in ${sshconfig}"
    error "Expected:"
    error "${expectedconfig}"
    error "Actual:"
    error "${actualconfig}"
    exit 1
fi
actualconfig=$(get_host_block "VeryImportant" "${sshconfig}")
if [ "${actualconfig}" == "${db_trim}" ]; then
    passed "Existing ssh config has been preserved in ${sshconfig}"
else
    error "Existing ssh config not found in ${sshconfig}"
    error "Expected:"
    error "${dummyblock}"
    error "Actual:"
    error "${actualconfig}"
    exit 1
fi

# Ensure vscode-remote-hpc ssh keys have been generated
if [ -f "${sshkey}" ] && [ -f "${sshkey}.pub" ]; then
    passed "ssh keys successfully generated"
else
    error "ssh keys not found"
    exit 1
fi

# Ensure existing ssh keys have been preserved
if [ -f "${dummykey}" ] && [ -f "${dummykey}.pub" ]; then
    passed "Existing ssh keys have been preserved"
else
    error "Existing ssh keys not found"
    exit 1
fi

# Uninstall vscode-remote-hpc again and ensure existing config is preserved
info "Uninstalling vscode-remote-hpc preserving original ssh config + keys"
"${VSRsetup}" "${VSRtester}" "${VSRhead}"

# Ensure ssh config file is still present
if [ -f "${sshconfig}" ]; then
    passed "Original ssh config file ${sshconfig} still present"
else
    error "Original ssh config file has been removed"
fi

# Ensure block has been wiped, but previous ssh configuration has not been removed
actualconfig=$(get_host_block "vscode-remote-hpc" "${sshconfig}")
if [ -z "${actualconfig}" ]; then
    passed "Host block removed from config file ${sshconfig}"
else
    error "Host block still present in config file ${sshconfig}"
    exit 1
fi

actualconfig=$(get_host_block "VeryImportant" "${sshconfig}")
if [ "${actualconfig}" == "${db_trim}" ]; then
    passed "Original ssh config has been preserved in ${sshconfig}"
else
    error "Original ssh config not matched in ${sshconfig}"
    error "Expected:"
    error "${dummyblock}"
    error "Actual:"
    error "${actualconfig}"
    exit 1
fi

passed "ALL PASSED"

exit 0
