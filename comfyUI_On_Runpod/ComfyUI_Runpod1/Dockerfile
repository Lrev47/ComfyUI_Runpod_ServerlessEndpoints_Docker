# Use the official PyTorch runtime image with CUDA and cuDNN
FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1
ENV CODE_SERVER_PORT=7777
ENV COMFYUI_PORT=8188
ENV RUNPOD_UPLOADER_PORT=2999

# Install prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
    curl \
    git \
    rsync \
    ca-certificates \
    build-essential \
    unzip \
    fuse \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install pip for Python
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && rm get-pip.py

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install rclone for network drive access
RUN curl https://rclone.org/install.sh | bash


# Install RunPod File Uploader
RUN curl -sSL https://github.com/kodxana/RunPod-FilleUploader/raw/main/scripts/installer.sh -o installer.sh && chmod +x installer.sh && ./installer.sh

# Clone ComfyUI and ComfyUI-Manager at stable versions
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /opt/comfyui && \
    cd /opt/comfyui && git checkout tags/v0.3.7

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /opt/comfyui-manager && \
    cd /opt/comfyui-manager && git checkout tags/2.55.5

# Install required Python dependencies
RUN pip install --upgrade pip && \
    pip install -r /opt/comfyui/requirements.txt --no-deps && \
    pip install -r /opt/comfyui-manager/requirements.txt --no-deps

# Copy start script and entrypoint
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose required ports
EXPOSE 8188 7777 2999

# Start the container
CMD ["/usr/local/bin/start.sh"]