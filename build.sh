#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# build.sh - generate the Morse Code Converter Vivado .xpr project via build.tcl
#
# Usage:   ./build.sh
# Env:     VIVADO   path to the vivado executable (default: "vivado" on PATH)
#-------------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VIVADO="${VIVADO:-vivado}"

if ! command -v "$VIVADO" >/dev/null 2>&1; then
    echo "ERROR: '$VIVADO' not found on PATH." >&2
    echo "       Source your Vivado settings (e.g. 'source /tools/Xilinx/Vivado/<ver>/settings64.sh')" >&2
    echo "       or set VIVADO=/path/to/vivado before running." >&2
    exit 1
fi

"$VIVADO" -mode batch -nojournal -nolog -source build.tcl
