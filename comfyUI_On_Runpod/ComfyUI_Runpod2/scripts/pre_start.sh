#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export APP="ComfyUI"
DOCKER_IMAGE_VERSION_FILE="/workspace/${APP}/docker_image_version"
TEMPLATE_VERSION="${TEMPLATE_VERSION:-1.0.0}"  # Default to 1.0.0 if not set

echo "Template version: ${TEMPLATE_VERSION}"

if [[ -e ${DOCKER_IMAGE_VERSION_FILE} ]]; then
    EXISTING_VERSION=$(cat ${DOCKER_IMAGE_VERSION_FILE})
else
    EXISTING_VERSION="0.0.0"
fi

rsync_with_progress() {
    stdbuf -i0 -o0 -e0 rsync -au --info=progress2 "$@" | stdbuf -i0 -o0 -e0 tr '\r' '\n' | stdbuf -i0 -o0 -e0 grep -oP '\d+%|\d+.\d+[mMgG]' | tqdm --bar-format='{l_bar}{bar}' --total=100 --unit='%' > /dev/null
}

sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        # Sync application to workspace to support Network volumes
        echo "Syncing ${APP} to workspace, please wait..."
        rsync_with_progress --remove-source-files /${APP}/ /workspace/${APP}/
    fi
}

fix_venvs() {
    echo "Fixing venv..."
    # Assuming fix_venv.sh is now present in 'build/' or remove this step if not needed
    # /fix_venv.sh /ComfyUI/venv /workspace/ComfyUI/venv
    # For now, remove or comment out if 'fix_venv.sh' is not present
    echo "fix_venv.sh not found, skipping virtual environment fix."
}

link_models() {
   # Link models and VAE if they are not already linked
   if [[ ! -L /workspace/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors ]]; then
       ln -s /sd-models/sd_xl_base_1.0.safetensors /workspace/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors
   fi

   if [[ ! -L /workspace/ComfyUI/models/checkpoints/sd_xl_refiner_1.0.safetensors ]]; then
       ln -s /sd-models/sd_xl_refiner_1.0.safetensors /workspace/ComfyUI/models/checkpoints/sd_xl_refiner_1.0.safetensors
   fi

   if [[ ! -L /workspace/ComfyUI/models/vae/sdxl_vae.safetensors ]]; then
       ln -s /sd-models/sdxl_vae.safetensors /workspace/ComfyUI/models/vae/sdxl_vae.safetensors
   fi
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        sync_apps
        fix_venvs
        link_models

        # Create logs directory
        mkdir -p /workspace/logs
    else
        echo "Existing version is the same as the template version, no syncing required."
    fi
else
    echo "Existing version is newer than the template version, not syncing!"
fi

# Remove starting application manager here as Supervisord is handling it

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the applications will not be started automatically"
    echo "You can launch them manually using the launcher scripts:"
    echo ""
    echo "   /scripts/start_comfyui.sh"
else
    /app-manager/scripts/start_comfyui.sh
fi

echo "All services have been started"
