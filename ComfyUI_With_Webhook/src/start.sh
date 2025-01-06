#!/usr/bin/env bash

# Use libtcmalloc for better memory management if present
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Function to start VS Code Server (optional)
start_code_server() {
    echo "CODE-SERVER: Starting Code Server..."
    mkdir -p /workspace/logs
    nohup code-server \
        --bind-addr 0.0.0.0:7777 \
        --auth none \
        --enable-proposed-api true \
        --disable-telemetry \
        /workspace &> /workspace/logs/code-server.log &
    echo "CODE-SERVER: Code Server started"
}

# Function to start RunPod Uploader (optional)
start_runpod_uploader() {
    echo "RUNPOD-UPLOADER: Starting RunPod Uploader..."
    mkdir -p /workspace/logs
    nohup /usr/local/bin/runpod-uploader &> /workspace/logs/runpod-uploader.log &
    echo "RUNPOD-UPLOADER: RunPod Uploader started"
}

# Custom Nodes from network volume
NETWORK_CUSTOM_NODES_PATH="/runpod-volume/ComfyUI/custom_nodes"
LOCAL_CUSTOM_NODES_PATH="/comfyui/custom_nodes"

echo "Copying custom nodes from network storage to local directory..."
mkdir -p "${LOCAL_CUSTOM_NODES_PATH}"

if [ -d "${NETWORK_CUSTOM_NODES_PATH}" ]; then
    cp -r "${NETWORK_CUSTOM_NODES_PATH}/." "${LOCAL_CUSTOM_NODES_PATH}/"
    echo "Custom nodes copied successfully."

    echo "Installing custom node dependencies..."
    find "${LOCAL_CUSTOM_NODES_PATH}" -type f -name 'requirements.txt' | while read req_file; do
        echo "Installing dependencies from $req_file"
        pip3 install --no-cache-dir -r "$req_file"
    done
else
    echo "Custom nodes directory does not exist: ${NETWORK_CUSTOM_NODES_PATH}"
fi

# Start VS Code Server (optional)
start_code_server

# Start RunPod Uploader (optional)
start_runpod_uploader

# Start ComfyUI and the RunPod handler
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    echo "runpod-worker-comfy: Starting ComfyUI (listening on 0.0.0.0:8188)"
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata --listen --extra-model-paths-config /comfyui/extra_model_paths.yaml &

    sleep 10

    echo "runpod-worker-comfy: Starting RunPod Handler on 0.0.0.0:8000"
    python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    echo "runpod-worker-comfy: Starting ComfyUI in normal mode"
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata --extra-model-paths-config /comfyui/extra_model_paths.yaml &

    sleep 10

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py
fi
