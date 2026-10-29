#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# run_hdl_smoke.sh — APB-003a evidence run (HDL only, no UVM)
#
#   1. slang elaboration of the smoke design (standard + DW=64 extension)
#   2. Verilator build + run of the positive smoke
#   3. three fault-injection runs on instance A (+APB_FAULT=1..3); each must
#      be detected by A's monitor while instance B stays clean
#   4. Verilator build + run with the DW=64 non-standard extension
#
# Usage: scripts/run_hdl_smoke.sh [output_dir]     (default: build/hdl_smoke)
# Needs: python3 with pyslang, verilator (>= 5.020) on PATH.
# Exit status 0 only if every step reports PASS.
#
# Toolchain gate (ARCHITECTURE_CONTRACT): this script launches slang and
# Verilator. Its presence is not approval to run it; AI contributors need
# explicit owner approval of these tools and commands first.
# -----------------------------------------------------------------------------
set -u

UVC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-${UVC_HOME}/build/hdl_smoke}"
mkdir -p "${OUT}"
cd "${UVC_HOME}"

FILELIST=filelists/apb_hdl_smoke.f
TOP=apb_hdl_smoke
failures=0
summary="${OUT}/summary.txt"
: > "${summary}"

record() {  # record <step> <PASS|FAIL> <detail>
  printf '%-34s %-4s %s\n' "$1" "$2" "${3//${OUT}/<out>}" | tee -a "${summary}"
  [ "$2" = PASS ] || failures=$((failures + 1))
}

{
  echo "date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "git:       $(git rev-parse HEAD 2>/dev/null || echo unknown)$(git diff --quiet 2>/dev/null || echo ' (dirty)')"
  echo "slang:     $(python3 -I -c 'import pyslang as p; v=p.VersionInfo; print(f"{v.getMajor()}.{v.getMinor()}.{v.getPatch()}+{v.getHash()}")' 2>/dev/null || echo missing)"
  echo "verilator: $(verilator --version 2>/dev/null || echo missing)"
  echo
} | tee -a "${summary}"

# 1. slang elaboration -------------------------------------------------------
for variant in std dw64; do
  defs=""; [ "${variant}" = dw64 ] && defs="+define+APB_ENABLE_DW64_EXTENSION"
  log="${OUT}/slang_${variant}.log"
  python3 -I scripts/slang_elab.py -F "${FILELIST}" --top "${TOP}" ${defs} > "${log}" 2>&1
  if grep -q "SLANG_RESULT: errors=0 diagnostics=0" "${log}"; then
    record "slang elaborate (${variant})" PASS "$(grep SLANG_RESULT "${log}")"
  else
    record "slang elaborate (${variant})" FAIL "see ${log}"
  fi
done

# 2-4. Verilator --------------------------------------------------------------
build() {  # build <variant> <extra verilator args...>
  local variant="$1"; shift
  local log="${OUT}/verilator_build_${variant}.log"
  rm -rf "${OUT}/obj_${variant}"
  if verilator --binary --timing -j 4 -Wall -Wno-fatal --top-module "${TOP}" \
       -F "${FILELIST}" "$@" --Mdir "${OUT}/obj_${variant}" -o "${TOP}" > "${log}" 2>&1; then
    record "verilator build (${variant})" PASS "$(grep -c '^%Warning' "${log}") warnings, see ${log}"
    return 0
  fi
  record "verilator build (${variant})" FAIL "see ${log}"
  return 1
}

run() {  # run <variant> <name> <plusargs...>
  local variant="$1" name="$2"; shift 2
  local log="${OUT}/sim_${name}.log"
  "${OUT}/obj_${variant}/${TOP}" "$@" > "${log}" 2>&1
  if grep -q "^SMOKE_RESULT: PASS" "${log}"; then
    record "sim ${name}" PASS "$(grep '^SMOKE_SUMMARY' "${log}")"
  else
    record "sim ${name}" FAIL "$(grep -E '^SMOKE_(RESULT|FAIL)' "${log}" | head -3 | tr '\n' ' ')"
  fi
}

if build std; then
  run std positive
  run std fault1_paddr_unstable    +APB_FAULT=1
  run std fault2_skip_setup        +APB_FAULT=2
  run std fault3_drop_psel_in_wait +APB_FAULT=3
fi
if build dw64 +define+APB_ENABLE_DW64_EXTENSION; then
  run dw64 positive_dw64_extension
fi

echo
if [ "${failures}" -eq 0 ]; then
  echo "HDL_SMOKE_OVERALL: PASS" | tee -a "${summary}"
  exit 0
fi
echo "HDL_SMOKE_OVERALL: FAIL (${failures} step(s))" | tee -a "${summary}"
exit 1
