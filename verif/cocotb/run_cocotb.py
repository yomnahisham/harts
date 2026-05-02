#!/usr/bin/env python3
"""Run cocotb tests against RTL blocks (Icarus). Invoke via `make test-cocotb` (uses verif/.venv)."""
from __future__ import annotations

import os
import sys
from pathlib import Path

from cocotb_tools.runner import get_runner

REPO = Path(__file__).resolve().parents[2]
RTL = REPO / "rtl"
TB = REPO / "verif" / "tb"
SIM = REPO / "verif" / "sim"


def run_case(name: str, toplevel: str, sources: list[Path], module: str) -> None:
    runner = get_runner("icarus")
    build_dir = SIM / f"cocotb_{name}"
    runner.build(
        sources=[str(p) for p in sources],
        hdl_toplevel=toplevel,
        build_dir=build_dir,
        always=True,
        timescale=("1ns", "1ps"),
    )
    env = os.environ.copy()
    env["PYTHONPATH"] = str(TB)
    runner.test(
        test_module=module,
        hdl_toplevel=toplevel,
        build_dir=build_dir,
        test_dir=str(TB),
        extra_env=env,
    )


def main() -> int:
    cases = [
        (
            "pq",
            "priority_queue",
            [RTL / "priority_queue.v", RTL / "pq_cell.v"],
            "test_priority_queue",
        ),
        (
            "sq",
            "sleep_queue",
            [RTL / "sleep_queue.v"],
            "test_sleep_queue",
        ),
        (
            "tt",
            "task_table",
            [RTL / "task_table.v"],
            "test_task_table",
        ),
        (
            "tm",
            "timer",
            [RTL / "timer.v"],
            "test_timer",
        ),
    ]
    for name, top, srcs, mod in cases:
        missing = [p for p in srcs if not p.is_file()]
        if missing:
            print("missing sources:", missing, file=sys.stderr)
            return 1
        print(f"== cocotb {name}: {mod} -> {top} ==")
        run_case(name, top, srcs, mod)
    print("cocotb: all module tests finished OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
