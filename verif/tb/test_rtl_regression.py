import os
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]


def run_cmd(args):
    proc = subprocess.run(
        args,
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        raise AssertionError(
            f"Command failed: {' '.join(args)}\n"
            f"stdout:\n{proc.stdout}\n"
            f"stderr:\n{proc.stderr}"
        )
    return proc.stdout


def test_verilog_regression_exercises_rtl():
    out = run_cmd(["make", "test-verilog"])
    assert "pass" in out.lower(), "expected pass markers from RTL testbenches"


def test_vcd_regression_semantic_checks():
    out = run_cmd(["make", "test-vcd"])
    assert "vcd sanity pass" in out.lower(), "expected VCD semantic checks to pass"


def test_cocotb_runner():
    vpy = REPO_ROOT / "verif" / ".venv" / "bin" / "python"
    script = REPO_ROOT / "verif" / "cocotb" / "run_cocotb.py"
    if not vpy.is_file():
        pytest.skip("run `make test-cocotb` once to create verif/.venv with cocotb")
    env = os.environ.copy()
    env["PYTHONPATH"] = str(REPO_ROOT / "verif" / "tb")
    subprocess.run([str(vpy), str(script)], cwd=REPO_ROOT, check=True, env=env)
