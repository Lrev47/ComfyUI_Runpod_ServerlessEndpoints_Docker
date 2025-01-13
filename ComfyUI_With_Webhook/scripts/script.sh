cd /workspace
python3 -m pip install --upgrade pip requests
python3 <<EOF
import os
import requests

BASE_URL = "https://huggingface.co/lrev47/ComfyUI_Models/resolve/main"
BASE_PATH = "/workspace"

models_to_download = {
    "checkpoints": [
        "autismmixSDXL_autismmixConfetti.safetensors",
        "cyberrealisticPony_v65.safetensors",
        "deliberate_v2.safetensors",
        "ponyDiffusionV6XL_v6StartWithThisOne.safetensors",
        "ponyRealism_V22MainVAE.safetensors",
        "prefectPonyXL_v3.safetensors",
        "sd_xl_base_1.0.safetensors",
        "stable_audio_model.ckpt",
        "v1-5-pruned.safetensors",
        "waiANINSFWPONYXL_v90.safetensors",
        "zavychromaxl_v90.safetensors"
    ],
    "clip": [
        "clip_l.safetensors",
        "t5_base_model.safetensors",
        "t5xxl_fp16.safetensors",
        "t5xxl_fp8_e4m3fn.safetensors"
    ],
    "controlnet": [
        "control_v11f1e_sd15_tile.pth",
        "control_v11f1p_sd15_depth.pth",
        "control_v11p_sd15_canny.pth",
        "control_v11p_sd15_inpaint.pth",
        "control_v11p_sd15_lineart.pth",
        "control_v11p_sd15_openpose.pth",
        "control_v1p_sd15_brightness.safetensors",
        "diffusers_xl_canny_full.safetensors"
    ],
    "diffusion_models": [
        "flux1-dev.safetensors",
        "mochi1PreviewVideo_previewBF16.safetensors"
    ],
    "loras": [
        "3d-render-v2.safetensors",
        "Cyber_UI.safetensors",
        "DTLDR-2.safetensors",
        "EPopmFubukiPony-04.safetensors",
        "G1FLUX.safetensors",
        "Herbst_Photo_35mm_Flux_V3.safetensors",
        "Kodak Portra 400 v2.safetensors",
        "MoviePoster03-02_CE_FLUX_128AIT.safetensors",
        "NLSTN.safetensors",
        "RetroAnimeFluxV1.safetensors",
        "RetroPop01-00_CE_FLUX_128AIT.safetensors",
        "Retro_glitch.safetensors",
        "The_Sims_1_Style_F1D.safetensors",
        "_Knight_of_The_Black_Veil__FLUX-000001.safetensors",
        "aidmaMJ6.1-FLUX-V0.3.safetensors",
        "aidmaTableTopMiniature-FLUX-V0.1.safetensors",
        "ancient.safetensors",
        "boreal-v2.safetensors",
        "cad.safetensors",
        "claymation-000012.safetensors",
        "cleanSketchJStyle_v10.safetensors",
        "flux-oilpainting1.3-00001.safetensors",
        "fluxRealSkin-V2.safetensors",
        "franklin_booth_style_flux_v1-000014.safetensors",
        "olympusd450_lora.safetensors"
    ],
    "unet": [
        "hyper-flux-16step-Q4_K_M.gguf"
    ],
    "upscale_models": [
        "4x-UltraSharp.pth",
        "4x_NickelbackFS_72000_G.pth",
        "lollypop.pth"
    ],
    "vae": [
        "fixFP16ErrorsSDXLLowerMemoryUse_v10.safetensors",
        "kl-f8-anime2.ckpt",
        "mochi_vae.safetensors",
        "orangemix.vae.pt",
        "sdxl_vae.safetensors",
        "vae-ft-mse-840000-ema-pruned.safetensors",
        "openai_consistency_decoder/decoder.pt",
        "Stable-Cascade/effnet_encoder.safetensors",
        "Stable-Cascade/stage_a.safetensors",
        "FLUX1/ae.safetensors"
    ]
}

local_dirs = {
    "checkpoints":       "ComfyUI/models/checkpoints/",
    "clip":              "ComfyUI/models/clip/",
    "controlnet":        "ComfyUI/models/controlnet/",
    "loras":             "ComfyUI/models/loras/",
    "unet":              "ComfyUI/models/unet/",
    "upscale_models":    "ComfyUI/models/upscale_models/",
    "vae":               "ComfyUI/models/vae/",
    "diffusion_models":  "ComfyUI/models/diffusion_models/"
}

def download_file(url, local_path):
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    print(f"Downloading {url} to {local_path}")
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(local_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
    print(f"Finished downloading {local_path}\n")

for folder, files in models_to_download.items():
    if folder not in local_dirs:
        print(f"Warning: No local directory mapping found for '{folder}'")
        continue
    local_dir = os.path.join(BASE_PATH, local_dirs[folder])
    for filename in files:
        url = f"{BASE_URL}/{folder}/{filename}"
        local_path = os.path.join(local_dir, filename)
        download_file(url, local_path)
EOF
