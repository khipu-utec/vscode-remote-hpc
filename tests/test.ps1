#
# Tests performing Windows installations/removals
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
#
# SPDX-License-Identifier: MIT
#

If ($Env:citest) {
    Write-Output "Running inside CI pipeline, turning on non-interactive mode"
    $Env:VSRunattended = $true
}
