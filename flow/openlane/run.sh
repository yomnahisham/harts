#!/usr/bin/env bash
set -e

if ! command -v flow.tcl >/dev/null 2>&1; then
  echo "openlane flow.tcl not found in path"
  echo "run this inside an openlane environment"
  exit 1
fi

flow.tcl -design "$(pwd)" -tag hw_scheduler_top_run
