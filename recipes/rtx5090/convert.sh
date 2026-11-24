#!/usr/bin/env bash
# Convert the pinned official Inkling-2-Mini checkpoint into a model pack.
# Usage: recipes/rtx5090/convert.sh [output path]   (run from the repo root)
set -euo pipefail
REV=7a67ae2314b44ef05c87fd1d4d311c58aaeb18f6
OUT=${1:-models/Inkling-2-Mini-NVFP4-MX8.basalt}
SNAP=$(hf download thinkingmachines/Inkling-2-Mini --revision "$REV" --quiet)
mkdir -p "$(dirname "$OUT")"
python3 tools/convert/convert.py --checkpoint "$SNAP" --out "$OUT" --workers 8
sha256sum "$OUT"
echo "expected 0a469fe5e81658619defb1d4795abcacf8fd1717aa0260afedc96e854f21f558"
