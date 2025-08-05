#!/bin/bash
set -e

# --- Model Configuration ---
MODEL_REPO="TheBloke/dolphin-2.7-mixtral-8x7b-GGUF"
MODEL_FILE="dolphin-2.7-mixtral-8x7b.Q6_K.gguf"
DOWNLOAD_URL="https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}"

# --- Server Configuration ---
HOST="0.0.0.0"
PORT="8000"
CONTEXT_SIZE="4096"
GPU_LAYERS="-1"

# --- Script Logic ---

# Check if model exists, if not, download it
if [ ! -f "$MODEL_FILE" ]; then
    echo "--- Model not found. Downloading ${MODEL_FILE} with aria2c... ---"
    apt-get update && apt-get install -y aria2
    aria2c -c -x 16 -s 16 -k 1M "$DOWNLOAD_URL" -o "$MODEL_FILE"
    echo "--- Model download complete. ---"
else
    echo "--- Model ${MODEL_FILE} already exists. Skipping download. ---"
fi

# Install/update dependencies, forcing re-compilation to ensure GPU support
echo "--- Installing/updating Python dependencies..."
export CMAKE_ARGS="-DGGML_CUDA=on"
export FORCE_CMAKE=1
pip install --upgrade --force-reinstall --no-cache-dir -r requirements.txt

# Start the server
echo "--- Starting OpenAI compatible server..."
python3 -m llama_cpp.server \
  --model "./${MODEL_FILE}" \
  --host "$HOST" \
  --port "$PORT" \
  --n_ctx "$CONTEXT_SIZE" \
  --n_gpu_layers "$GPU_LAYERS" \
  --tensor_split '[1]' \
  --no_mmap \
  --verbose "true"

echo "--- Server started successfully. ---"
