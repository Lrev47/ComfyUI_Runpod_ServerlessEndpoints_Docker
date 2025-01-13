# Use the official NVIDIA CUDA base image
FROM nvidia/cuda:12.1.1-base-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV APP_MANAGER_PORT=8000
ENV COMFYUI_PORT=3021

# Install essential packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    python3 \
    python3-venv \
    python3-pip \
    rsync \
    python3-tqdm \
    supervisor \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (includes npm)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash appuser

# Set working directory
WORKDIR /workspace

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# Navigate to ComfyUI directory
WORKDIR /workspace/ComfyUI


# Create and activate Python virtual environment
RUN python3 -m venv venv

# Install Python dependencies
RUN /bin/bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

# Navigate back to workspace
WORKDIR /workspace

# Set working directory for app-manager
WORKDIR /workspace/app-manager

# Copy package.json and package-lock.json first for Docker caching
COPY app-manager/package.json /workspace/app-manager/package.json
COPY app-manager/package-lock.json /workspace/app-manager/package-lock.json

# Install Application Manager dependencies using npm ci
RUN npm ci

# Copy the rest of the Application Manager code
COPY app-manager/ /workspace/app-manager/

# Create logs directory
RUN mkdir -p /workspace/logs

# Set permissions for logs directory
RUN chown -R appuser:appuser /workspace/logs

# Change ownership of workspace
RUN chown -R appuser:appuser /workspace

# Switch to the non-root user
USER appuser

# Copy Supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy NGINX configuration
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Expose necessary ports
EXPOSE 80 8000 3021

# Start supervisord to manage processes with explicit config file
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
