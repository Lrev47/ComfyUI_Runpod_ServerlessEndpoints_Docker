# Dockerfile

# Stage 1: Base image with CUDA 12.1.105 and Ubuntu 22.04
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04 AS base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately (no buffering)
ENV PYTHONUNBUFFERED=1

# Install Python, git, and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1 && \
    apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies
RUN pip3 install --upgrade --no-cache-dir \
    torch==2.4.0 \
    torchvision==0.19.0 \
    torchaudio==2.4.0 \
    --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --upgrade -r requirements.txt

# Install runpod, requests, and pyyaml
RUN pip3 install runpod requests pyyaml

# Copy extra_model_paths.yaml so ComfyUI sees custom model paths
ADD src/extra_model_paths.yaml /comfyui/
RUN chmod 644 /comfyui/extra_model_paths.yaml

# Return to root
WORKDIR /

# Add the "start.sh" script and "rp_handler.py"
ADD src/start.sh /start.sh
ADD src/rp_handler.py /rp_handler.py

RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
