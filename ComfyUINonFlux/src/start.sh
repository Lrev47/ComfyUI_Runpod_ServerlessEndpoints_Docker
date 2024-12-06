#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"


# Function to start VS Code Server
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

# Function to start RunPod Uploader
start_runpod_uploader() {
    echo "RUNPOD-UPLOADER: Starting RunPod Uploader..."
    mkdir -p /workspace/logs
    nohup /usr/local/bin/runpod-uploader &> /workspace/logs/runpod-uploader.log &
    echo "RUNPOD-UPLOADER: RunPod Uploader started"
}


# Define the source and destination directories

# Define source and destination for custom nodes
NETWORK_CUSTOM_NODES_PATH="/runpod-volume/ComfyUI/custom_nodes"
LOCAL_CUSTOM_NODES_PATH="/comfyui/custom_nodes"

echo "Copying custom nodes from network storage to local directory..."

# Create the local custom nodes directory if it doesn't exist
mkdir -p "${LOCAL_CUSTOM_NODES_PATH}"

# Copy custom nodes
if [ -d "${NETWORK_CUSTOM_NODES_PATH}" ]; then
    cp -r "${NETWORK_CUSTOM_NODES_PATH}/." "${LOCAL_CUSTOM_NODES_PATH}/"
    echo "Custom nodes copied successfully."

    # Install dependencies from each requirements.txt
    echo "Installing custom node dependencies..."
    find "${LOCAL_CUSTOM_NODES_PATH}" -type f -name 'requirements.txt' | while read req_file; do
        echo "Installing dependencies from $req_file"
        pip3 install --no-cache-dir -r "$req_file"
    done
else
    echo "Custom nodes directory does not exist: ${NETWORK_CUSTOM_NODES_PATH}"
fi

NETWORK_STORAGE_PATH="/runpod-volume/ComfyUI/models"
LOCAL_MODEL_PATH="/comfyui/models"

echo "Copying specific models from network storage to local model directory..."

# List of specific model files to copy
MODEL_FILES=(
    "vae/sdxl_vae.safetensors"
    "checkpoints/cyberrealisticPony_v65.safetensors"
    "checkpoints/sd_xl_base_1.0.safetensors"
    "upscale_models/4x-UltraSharp.pth"
    "loras/ivan-bilibin_pony_v1.safetensors"
    "upscale_models/4x_NickelbackFS_72000_G.pth"
    "checkpoints/ponyRealism_V22MainVAE.safetensors"
    "checkpoints/ponyDiffusionV6XL_v6StartWithThisOne.safetensors"
    "loras/DTLDR-2.safetensors"
    "checkpoints/prefectPonyXL_v3.safetensors"
    "loras/NLSTN.safetensors"
    "upscale_models/4x-UltraSharp.pth"
)

# Function to copy a model file
copy_model_file() {
    local RELATIVE_PATH="$1"
    local SOURCE_FILE="${NETWORK_STORAGE_PATH}/${RELATIVE_PATH}"
    local DESTINATION_FILE="${LOCAL_MODEL_PATH}/${RELATIVE_PATH}"
    local DESTINATION_DIR

    DESTINATION_DIR=$(dirname "${DESTINATION_FILE}")

    # Create the destination directory if it doesn't exist
    if [ ! -d "${DESTINATION_DIR}" ]; then
        mkdir -p "${DESTINATION_DIR}"
        echo "Created directory: ${DESTINATION_DIR}"
    fi

    # Copy the file if it exists
    if [ -f "${SOURCE_FILE}" ]; then
        cp "${SOURCE_FILE}" "${DESTINATION_FILE}"
        echo "Copied ${SOURCE_FILE} to ${DESTINATION_FILE}"
    else
        echo "Source file does not exist: ${SOURCE_FILE}"
    fi
}

# Iterate over the list of model files and copy them
for MODEL_FILE in "${MODEL_FILES[@]}"; do
    copy_model_file "${MODEL_FILE}"
done

echo "Model copying complete."



# Continue with the original script

# Start VS Code Server
start_code_server

# Start RunPod Uploader
start_runpod_uploader

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    echo "runpod-worker-comfy: Starting ComfyUI"
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata --listen &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    echo "runpod-worker-comfy: Starting ComfyUI"
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py
fi
