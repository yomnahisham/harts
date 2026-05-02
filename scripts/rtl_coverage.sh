#!/usr/bin/env bash
# Build and run Verilator line + expression coverage sims, merge .dat, emit lcov .info + annotated tree.
# Requires: verilator, verilator_coverage (optional: lcov genhtml for HTML).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/verif/sim/coverage_rtl"
OBJ="${OUT}/obj"
REPORT="${OUT}/report"
mkdir -p "$OBJ" "$REPORT"

if ! command -v verilator >/dev/null 2>&1; then
  echo "rtl_coverage: verilator not found; skip or install Verilator" >&2
  exit 1
fi

run_cov() {
  local name="$1"
  shift
  local sub="${OBJ}/${name}"
  rm -rf "$sub"
  mkdir -p "$sub"
  (
    cd "$sub"
    verilator --binary --coverage-line --coverage-expr --timing -Wno-fatal -Wno-WIDTHEXPAND \
      -Mdir . -j 0 -o "V${name}_cov" \
      "$@" --top-module "$(basename "$name")"
    "./V${name}_cov"
    test -f coverage.dat
    cp coverage.dat "${REPORT}/${name}.dat"
  )
}

echo "== rtl_coverage: timer =="
run_cov tb_timer "${ROOT}/verif/tb_verilog/tb_timer.v" "${ROOT}/rtl/timer.v"

echo "== rtl_coverage: priority_queue =="
run_cov tb_priority_queue \
  "${ROOT}/verif/tb_verilog/tb_priority_queue.v" \
  "${ROOT}/rtl/priority_queue.v" \
  "${ROOT}/rtl/pq_cell.v"

echo "== rtl_coverage: merge + lcov info =="
verilator_coverage --write "${REPORT}/merged.dat" \
  "${REPORT}/tb_timer.dat" \
  "${REPORT}/tb_priority_queue.dat"
verilator_coverage --write-info "${REPORT}/merged.info" "${REPORT}/merged.dat"

rm -rf "${REPORT}/annotate"
verilator_coverage --annotate "${REPORT}/annotate" --annotate-min 1 "${REPORT}/merged.dat"

echo "rtl_coverage: wrote ${REPORT}/merged.info and ${REPORT}/annotate/"
if command -v lcov >/dev/null 2>&1; then
  lcov --summary "${REPORT}/merged.info" 2>/dev/null || true
fi
if command -v genhtml >/dev/null 2>&1; then
  genhtml --legend -o "${REPORT}/html" "${REPORT}/merged.info"
  echo "rtl_coverage: HTML -> ${REPORT}/html/index.html"
else
  echo "rtl_coverage: optional: brew install lcov for genhtml + lcov --summary"
fi
