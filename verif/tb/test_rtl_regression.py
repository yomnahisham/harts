import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


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
