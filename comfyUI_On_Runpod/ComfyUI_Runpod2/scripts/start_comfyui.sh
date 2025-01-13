#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "Starting ComfyUI"

cd /workspace/ComfyUI || { echo "ComfyUI directory not found!"; exit 1; }

source venv/bin/activate || { echo "Failed to activate virtual environment!"; exit 1; }

TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
if [[ -n "$TCMALLOC" ]]; then
    export LD_PRELOAD="${TCMALLOC}"
    echo "Preloaded tcmalloc: ${TCMALLOC}"
else
    echo "tcmalloc not found, proceeding without it."
fi

# Start ComfyUI
python3 main.py --listen 0.0.0.0 --port 3021 > /workspace/logs/comfyui.log 2>&1 &

if [ $? -eq 0 ]; then
    echo "ComfyUI started successfully."
else
    echo "Failed to start ComfyUI."
fi

deactivate
