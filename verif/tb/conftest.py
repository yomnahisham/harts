import sys
from pathlib import Path

# Allow `from golden_model import ...` when pytest is run from repo root.
sys.path.insert(0, str(Path(__file__).resolve().parent))
