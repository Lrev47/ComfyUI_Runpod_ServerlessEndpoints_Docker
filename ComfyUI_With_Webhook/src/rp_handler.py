# src/rp_handler.py

import runpod
from runpod.serverless.utils import rp_upload
import json
import urllib.request
import urllib.parse
import time
import os
import requests
import base64
from io import BytesIO

# Time to wait between ComfyUI availability checks
COMFY_API_AVAILABLE_INTERVAL_MS = 500
COMFY_API_AVAILABLE_MAX_RETRIES = 240

# Poll interval to check prompt history
COMFY_POLLING_INTERVAL_MS = int(os.environ.get("COMFY_POLLING_INTERVAL_MS", 500))
COMFY_POLLING_MAX_RETRIES = int(os.environ.get("COMFY_POLLING_MAX_RETRIES", 600))

# Where ComfyUI is listening
COMFY_HOST = "127.0.0.1:8188"

# Enforce a clean state after each job
REFRESH_WORKER = os.environ.get("REFRESH_WORKER", "false").lower() == "true"


def validate_input(job_input):
    """
    Validates the incoming job input.
    We also parse 'userId' and 'productId' if provided.
    """
    if job_input is None:
        return None, "Please provide input"

    if isinstance(job_input, str):
        try:
            job_input = json.loads(job_input)
        except json.JSONDecodeError:
            return None, "Invalid JSON format in input"

    # Check if warm-up request
    if job_input.get("action") == "warmup":
        return {"action": "warmup"}, None

    if "workflow" not in job_input:
        return None, "Missing 'workflow' parameter"

    workflow = job_input["workflow"]
    images = job_input.get("images")
    callback_url = job_input.get("callbackUrl")

    # Parse optional userId and productId; default to None if missing
    user_id = job_input.get("userId", None)
    product_id = job_input.get("productId", None)

    # Validate images
    if images is not None:
        if not isinstance(images, list) or not all("name" in img and "image" in img for img in images):
            return None, "'images' must be a list of objects with 'name' and 'image' keys"

    return {
        "workflow": workflow,
        "images": images,
        "callbackUrl": callback_url,
        "userId": user_id,       # possibly None
        "productId": product_id  # possibly None
    }, None


def check_server(url, retries=500, delay=50):
    """
    Poll a given URL until it responds with 200 or until we exceed retries.
    """
    for i in range(retries):
        try:
            response = requests.get(url)
            if response.status_code == 200:
                print("runpod-worker-comfy - API is reachable")
                return True
        except requests.RequestException:
            pass
        time.sleep(delay / 1000)
    print(f"runpod-worker-comfy - Failed to connect to server at {url} after {retries} attempts.")
    return False


def upload_images(images):
    """
    Uploads base64 images to ComfyUI's /upload/image endpoint (if any).
    """
    if not images:
        return {"status": "success", "message": "No images to upload", "details": []}

    responses = []
    upload_errors = []

    print("runpod-worker-comfy - uploading images to ComfyUI...")

    for image in images:
        name = image["name"]
        image_data = image["image"]
        blob = base64.b64decode(image_data)

        files = {
            "image": (name, BytesIO(blob), "image/png"),
            "overwrite": (None, "true"),
        }

        response = requests.post(f"http://{COMFY_HOST}/upload/image", files=files)
        if response.status_code != 200:
            upload_errors.append(f"Error uploading {name}: {response.text}")
        else:
            responses.append(f"Successfully uploaded {name}")

    if upload_errors:
        print("runpod-worker-comfy - some images failed to upload")
        return {
            "status": "error",
            "message": "Some images failed to upload",
            "details": upload_errors,
        }

    return {
        "status": "success",
        "message": "All images uploaded",
        "details": responses,
    }


def queue_workflow(workflow):
    """
    Queues a workflow by sending JSON to ComfyUI's /prompt endpoint.
    """
    data = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(f"http://{COMFY_HOST}/prompt", data=data)
    return json.loads(urllib.request.urlopen(req).read())


def get_history(prompt_id):
    """
    Fetches the prompt history for a given prompt_id from ComfyUI.
    """
    with urllib.request.urlopen(f"http://{COMFY_HOST}/history/{prompt_id}") as response:
        return json.loads(response.read())


def base64_encode(img_path):
    """
    Reads a local image file into base64.
    """
    with open(img_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def process_output_images(outputs, job_id):
    """
    Locates the generated image in the outputs,
    either uploads to S3 via runpod.serverless.utils.rp_upload,
    or returns base64 if S3 is not configured.
    """
    COMFY_OUTPUT_PATH = os.environ.get("COMFY_OUTPUT_PATH", "/comfyui/output")

    output_images = None
    for node_id, node_output in outputs.items():
        if "images" in node_output:
            for img in node_output["images"]:
                output_images = os.path.join(img["subfolder"], img["filename"])

    print("runpod-worker-comfy - image generation done")
    local_image_path = f"{COMFY_OUTPUT_PATH}/{output_images}"
    print(f"runpod-worker-comfy - local image path: {local_image_path}")

    if os.path.exists(local_image_path):
        if os.environ.get("BUCKET_ENDPOINT_URL", False):
            # Upload to S3
            image_url = rp_upload.upload_image(job_id, local_image_path)
            print("runpod-worker-comfy - image uploaded to AWS S3")
            return {
                "status": "success",
                "message": image_url,
            }
        else:
            # Return as base64
            image_b64 = base64_encode(local_image_path)
            print("runpod-worker-comfy - image converted to base64")
            return {
                "status": "success",
                "message": image_b64,
            }
    else:
        print("runpod-worker-comfy - image not found in output folder")
        return {
            "status": "error",
            "message": f"Image not found at {local_image_path}",
        }


def handler(job):
    """
    Main handler function for RunPod ephemeral requests.

    Steps:
      1) parse job input
      2) handle warmup if requested
      3) validate workflow + optional images + callback
      4) poll ComfyUI
      5) callback if provided
      6) return ephemeral job COMPLETED
    """
    job_input = job["input"]
    if not job_input:
        return {"error": "No input provided"}

    # 1) Check warm-up
    if job_input.get("action") == "warmup":
        print("Received warm-up request")
        check_server(
            f"http://{COMFY_HOST}",
            COMFY_API_AVAILABLE_MAX_RETRIES,
            COMFY_API_AVAILABLE_INTERVAL_MS
        )
        return {"status": "GPU warmed up"}

    # 2) Validate input
    validated_data, error_message = validate_input(job_input)
    if error_message:
        return {"error": error_message}

    workflow = validated_data["workflow"]
    images = validated_data["images"]
    callback_url = validated_data["callbackUrl"]

    # userId, productId (default None if not provided)
    user_id = validated_data["userId"]
    product_id = validated_data["productId"]

    # 3) Ensure ComfyUI is available
    check_server(
        f"http://{COMFY_HOST}",
        COMFY_API_AVAILABLE_MAX_RETRIES,
        COMFY_API_AVAILABLE_INTERVAL_MS
    )

    # 4) Upload images if any
    upload_result = upload_images(images)
    if upload_result["status"] == "error":
        return upload_result

    # 5) Queue the workflow
    try:
        queued = queue_workflow(workflow)
        prompt_id = queued["prompt_id"]
        print(f"runpod-worker-comfy - queued workflow ID {prompt_id}")
    except Exception as e:
        return {"error": f"Error queuing workflow: {str(e)}"}

    # 6) Generate (poll for prompt to finish)
    print("runpod-worker-comfy - generating image (polling ComfyUI internally)...")
    retries = 0
    while retries < COMFY_POLLING_MAX_RETRIES:
        history = get_history(prompt_id)
        if prompt_id in history and history[prompt_id].get("outputs"):
            break
        else:
            time.sleep(COMFY_POLLING_INTERVAL_MS / 1000)
            retries += 1

    if retries >= COMFY_POLLING_MAX_RETRIES:
        return {"error": "Max retries reached while waiting for generation."}

    # 7) Process output images
    outputs = history[prompt_id].get("outputs")
    images_result = process_output_images(outputs, job["id"])

    # 8) If we have a callbackUrl, POST final result
    if callback_url:
        payload = {
        "jobId": job["id"],
        "status": images_result["status"],
        "message": images_result["message"],
        "userId": user_id,
        "productId": product_id
    }
    print(f"runpod-worker-comfy - callback to {callback_url} with payload {payload}")

    try:
        # Send the POST and store the response in one statement
        resp = requests.post(callback_url, json=payload, timeout=15)
        print(f"runpod-worker-comfy - callbackUrl responded with {resp.status_code}")

        # If you want to raise an exception on 4xx/5xx:
        # resp.raise_for_status()

    except Exception as e:
        print(f"runpod-worker-comfy - Error calling callbackUrl: {e}")


    # 9) Return ephemeral job final response
    result = {
        "status": "COMPLETED",
        "output": images_result,
        "refresh_worker": REFRESH_WORKER
    }

    return result


# If run directly, start serverless
if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
