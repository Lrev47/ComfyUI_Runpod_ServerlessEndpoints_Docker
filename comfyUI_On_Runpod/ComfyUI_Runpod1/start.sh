#!/usr/bin/env bash
set -e

# Function to create directories if they don't exist
create_model_directories() {
    echo "Creating model directories..."
    MODEL_DIRECTORIES=(
        "checkpoints"
        "clip"
        "clip_vision"
        "configs"
        "controlnet"
        "diffusers"
        "diffusion_models"
        "embeddings"
        "gligen"
        "hypernetworks"
        "loras"
        "photomaker"
        "style_models"
        "text_encoders"
        "unet"
        "upscale_models"
        "vae"
        "vae_approx"
    )
    for MODEL_DIRECTORY in ${MODEL_DIRECTORIES[@]}; do
        mkdir -p "/opt/comfyui/models/$MODEL_DIRECTORY"
    done
}

# Symlink ComfyUI-Manager
symlink_comfyui_manager() {
    echo "Creating symlink for ComfyUI-Manager..."
    rm -f /opt/comfyui/custom_nodes/ComfyUI-Manager
    ln -s /opt/comfyui-manager /opt/comfyui/custom_nodes/ComfyUI-Manager
}

# Install custom node dependencies
install_custom_node_dependencies() {
    echo "Installing requirements for custom nodes..."
    for NODE_DIR in /opt/comfyui/custom_nodes/*; do
        if [ -f "$NODE_DIR/requirements.txt" ]; then
            echo "Installing requirements for $(basename $NODE_DIR)..."
            pip install --requirement "$NODE_DIR/requirements.txt"
        fi
    done
}

# Mount Network Drive (optional)
mount_network_drive() {
    echo "Mounting network drive..."
    if [ -n "$NETWORK_DRIVE" ]; then
        rclone mount "$NETWORK_DRIVE" /opt/comfyui/network_drive --daemon
        echo "Mounted network drive to /opt/comfyui/network_drive"
    else
        echo "No network drive specified. Skipping mount."
    fi
}

# Start services
start_services() {
    # Start Code Server
    echo "Starting code-server..."
    nohup code-server --bind-addr 0.0.0.0:${CODE_SERVER_PORT} --auth none /workspace &> /var/log/codeserver.log &

    # Start ComfyUI
    echo "Starting ComfyUI..."
    cd /opt/comfyui
    nohup python main.py --listen 0.0.0.0 --port ${COMFYUI_PORT} &> /workspace/logs/comfyui.log &

    # Start RunPod File Uploader
    echo "Starting RunPod Uploader..."
    nohup runpod-uploader --port ${RUNPOD_UPLOADER_PORT} &> /workspace/logs/runpod-uploader.log &

    echo "All services are running."
}

# Main execution
echo "Initializing container..."
create_model_directories
symlink_comfyui_manager
install_custom_node_dependencies
mount_network_drive
start_services

# Keep container alive
tail -f /dev/null
