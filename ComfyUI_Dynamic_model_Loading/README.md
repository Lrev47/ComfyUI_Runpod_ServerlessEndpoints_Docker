# ComfyUI Docker Image for RunPod Serverless Workers

This repository contains a Dockerfile and scripts to build a Docker image for running [ComfyUI](https://github.com/comfyanonymous/ComfyUI) on RunPod serverless GPU endpoints. The image includes custom nodes and models loaded from network storage.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Setup Instructions](#setup-instructions)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Organize Your Custom Nodes and Models](#2-organize-your-custom-nodes-and-models)
  - [3. Update the `start.sh` Script](#3-update-the-startsh-script)
  - [4. Build the Docker Image](#4-build-the-docker-image)
  - [5. Push the Image to Docker Hub](#5-push-the-image-to-docker-hub)
  - [6. Deploy on RunPod](#6-deploy-on-runpod)
  - [7. Test the Deployment](#7-test-the-deployment)
- [Dockerfile Explanation](#dockerfile-explanation)
- [`start.sh` Script Explanation](#startsh-script-explanation)
- [Updating Models and Custom Nodes](#updating-models-and-custom-nodes)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- **ComfyUI**: A powerful and modular Stable Diffusion UI and API.
- **Custom Nodes**: Includes custom nodes from your network storage.
- **Models from Network Storage**: Copies specified models from network storage to the container at startup.
- **Automatic Dependency Installation**: Installs dependencies for custom nodes based on their `requirements.txt` files.
- **Optimized for RunPod Serverless Workers**: Configured to work with RunPod's serverless GPU endpoints, including correct network storage paths.

## Prerequisites

- **Docker**: Ensure you have Docker installed on your machine.
- **RunPod Account**: Access to RunPod's serverless GPU endpoints.
- **Network Storage**: Models and custom nodes stored in RunPod's network storage.

## Directory Structure

```
your-project/
├── Dockerfile
├── start.sh
├── rp_handler.py
├── extra_model_paths.yaml
├── test_input.json
├── README.md
└── src/
    ├── custom_nodes/
    │   ├── CustomNode1/
    │   │   ├── __init__.py
    │   │   ├── requirements.txt
    │   │   └── (other files)
    │   ├── CustomNode2/
    │   │   ├── __init__.py
    │   │   ├── requirements.txt
    │   │   └── (other files)
    │   └── (additional custom nodes)
    └── models/
        ├── checkpoints/
        │   ├── model1.safetensors
        │   ├── model2.safetensors
        │   └── (other model files)
        ├── vae/
        ├── loras/
        └── (other model directories)
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your_username/your_repository.git
cd your_repository
```

### 2. Organize Your Custom Nodes and Models

- **Custom Nodes**: Place your custom node folders inside `src/custom_nodes/`.
- **Models**: Place your model files inside `src/models/` following the appropriate directory structure (e.g., `checkpoints/`, `vae/`, `loras/`).

### 3. Update the `start.sh` Script

The `start.sh` script handles copying models and custom nodes from network storage and installing dependencies.

- **Network Storage Paths**: Ensure the paths in `start.sh` match your network storage setup. By default, network storage is mounted at `/runpod-volume/` in RunPod serverless workers.

```bash
# Define source and destination for custom nodes
NETWORK_CUSTOM_NODES_PATH="/runpod-volume/ComfyUI/custom_nodes"
LOCAL_CUSTOM_NODES_PATH="/comfyui/custom_nodes"

# Define source and destination for models
NETWORK_STORAGE_PATH="/runpod-volume/ComfyUI/models"
LOCAL_MODEL_PATH="/comfyui/models"
```

- **Model Files to Copy**: Update the `MODEL_FILES` array in `start.sh` with the relative paths to the models you want to copy from network storage.

```bash
MODEL_FILES=(
    "checkpoints/model1.safetensors"
    "vae/vae_model.safetensors"
    "loras/lora_model.safetensors"
    # Add more models as needed
)
```

### 4. Build the Docker Image

Build the Docker image using the Dockerfile.

```bash
docker build -t your_dockerhub_username/comfyui-runpod:v1 .
```

### 5. Push the Image to Docker Hub

Push the Docker image to your Docker Hub repository.

```bash
docker push your_dockerhub_username/comfyui-runpod:v1
```

### 6. Deploy on RunPod

- **Create a Serverless Endpoint**: In the RunPod dashboard, create a new serverless GPU endpoint.
- **Use the Docker Image**: Set the container image to `your_dockerhub_username/comfyui-runpod:v1`.
- **Attach Network Storage**:
  - In the advanced settings, select your network storage under **'Network Volume'**.
- **Environment Variables**: Set any necessary environment variables.

### 7. Test the Deployment

- **Monitor Logs**: After deploying, monitor the logs to ensure the application starts correctly and that models and custom nodes are loaded.
- **Submit Jobs**: Test the endpoint by submitting jobs to ensure it processes prompts as expected.
