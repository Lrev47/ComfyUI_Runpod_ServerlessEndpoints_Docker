variable "REGISTRY" {
    default = "docker.io"
}

variable "REGISTRY_USER" {
    default = "lrev"
}

variable "APP" {
    default = "comfyui"
}

variable "RELEASE" {
    default = "1.0"
}

variable "CU_VERSION" {
    default = "121"
}

variable "BASE_IMAGE_REPOSITORY" {
    default = "nvidia/cuda"
}

variable "BASE_IMAGE_VERSION" {
    default = "12.1.1-base-ubuntu22.04"
}

variable "CUDA_VERSION" {
    default = "12.1.1"
}

variable "TORCH_VERSION" {
    default = "2.3.0"
}

variable "XFORMERS_VERSION" {
    default = "0.0.15"
}

variable "TEMPLATE_VERSION" {
    default = "1.0.0"
}

target "default" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
        BASE_IMAGE = "${BASE_IMAGE_REPOSITORY}:${BASE_IMAGE_VERSION}"
        INDEX_URL = "https://download.pytorch.org/whl/cu${CU_VERSION}"
        TORCH_VERSION = "${TORCH_VERSION}"
        XFORMERS_VERSION = "${XFORMERS_VERSION}"
        COMFYUI_COMMIT = "2f03201690e0fb8a3ec551a125b20d89c9019a02"
        APP_MANAGER_VERSION = "1.1.0"
        CIVITAI_DOWNLOADER_VERSION = "2.1.0"
        TEMPLATE_VERSION = "${TEMPLATE_VERSION}"
    }
}
