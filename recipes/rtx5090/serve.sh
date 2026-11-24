#!/usr/bin/env bash
# Serve the RTX 5090 recipe: OpenAI-compatible API on 127.0.0.1:8080.
# Usage: recipes/rtx5090/serve.sh [pack path]   (run from the repo root)
set -euo pipefail
PACK=${1:-models/Inkling-2-Mini-NVFP4-MX8.basalt}
exec bin/basalt serve "$PACK" --alias inkling --port 8080 \
    --max-context 262144 --answer-room 0
