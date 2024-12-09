# Serverless Endpoints for AI Image Generation

This repository contains Docker files and configurations for a serverless architecture designed to handle AI image generation tasks. The setup ensures cost efficiency by utilizing GPU resources only during the image generation process, thereby avoiding continuous GPU usage.

## Overview

Each Docker file in this repository:

- Starts the RunPod server.
- Downloads necessary dependencies and requirements.
- Copies several AI models from a shared network storage to the GPU memory for faster initialization.

This serverless approach is optimized to reduce costs while maintaining high performance during active use.

## Current Endpoints

### 1. **Flux**

- **Description**: Flux is considered the top open-source AI image generation model developed by Black Forest Labs.
- **Purpose**: Hosted on its dedicated endpoint due to its larger file size and resource requirements.

### 2. **NonFlux**

- **Description**: Hosts all other AI image generation models with smaller file sizes.
- **Purpose**: Optimized for lightweight models that require less GPU memory.

## Future Plans

- Expand the architecture to include endpoints for audio and video generation models.
- Continue utilizing Docker containers and RunPod for scalability and efficiency.

## Hosting Details

- All endpoints are containerized using Docker.
- Hosted on [RunPod](https://www.runpod.io/) for serverless operation.

## Contributing

Contributions to improve this architecture or expand its capabilities are welcome. Please feel free to open an issue or submit a pull request.

---

**Note**: This repository is optimized for advanced AI workflows. Ensure that you have the necessary resources and permissions configured before deploying.
