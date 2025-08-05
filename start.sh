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
GPU_LAYERS="-1"  # -1 means use all available GPU layers

# --- Environment Setup ---
echo "--- Setting up environment ---"

# Update system packages
apt-get update && apt-get install -y \
    wget \
    curl \
    aria2 \
    build-essential \
    cmake \
    nvidia-cuda-toolkit \
    python3-dev \
    python3-pip

# Set CUDA environment variables
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# --- Model Download ---
if [ ! -f "$MODEL_FILE" ]; then
    echo "--- Model not found. Downloading ${MODEL_FILE} with aria2c... ---"
    aria2c -c -x 16 -s 16 -k 1M "$DOWNLOAD_URL" -o "$MODEL_FILE"
    echo "--- Model download complete. ---"
else
    echo "--- Model ${MODEL_FILE} already exists. Skipping download. ---"
fi

# --- Python Dependencies ---
echo "--- Installing/updating Python dependencies..."

# Create requirements.txt if it doesn't exist
if [ ! -f "requirements.txt" ]; then
    echo "--- Creating requirements.txt ---"
    cat > requirements.txt << EOF
llama-cpp-python[server]
numpy
fastapi
uvicorn
pydantic
typing-extensions
sse-starlette
starlette-context
EOF
fi

# Detect GPU architecture
echo "--- Detecting GPU architecture ---"
GPU_ARCH=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader,nounits | head -1 | tr -d '.')
if [ -z "$GPU_ARCH" ]; then
    echo "Warning: Could not detect GPU architecture, using common architectures"
    GPU_ARCH="75;80;86;89;90"
else
    echo "Detected GPU compute capability: $GPU_ARCH"
fi

# Set compilation flags for CUDA support
export CMAKE_ARGS="-DGGML_CUDA=on -DCMAKE_CUDA_ARCHITECTURES=${GPU_ARCH}"
export FORCE_CMAKE=1
export CUDACXX=/usr/local/cuda/bin/nvcc

# Install with CUDA support
pip install --upgrade pip setuptools wheel
CMAKE_ARGS="-DGGML_CUDA=on -DCMAKE_CUDA_ARCHITECTURES=${GPU_ARCH}" pip install --upgrade --force-reinstall --no-cache-dir llama-cpp-python[server]

# Install other requirements
pip install --upgrade --force-reinstall --no-cache-dir -r requirements.txt

# --- Verify GPU Access ---
echo "--- Checking GPU availability ---"
nvidia-smi || echo "Warning: nvidia-smi not available"
python3 -c "
import subprocess
try:
    result = subprocess.run(['nvidia-smi'], capture_output=True, text=True)
    if result.returncode == 0:
        print('GPU detected successfully')
    else:
        print('GPU detection failed')
except:
    print('nvidia-smi command failed')
"

# --- Start Server ---
echo "--- Starting OpenAI compatible server..."
echo "Model: $MODEL_FILE"
echo "Host: $HOST"
echo "Port: $PORT"
echo "Context Size: $CONTEXT_SIZE"
echo "GPU Layers: $GPU_LAYERS"

python3 -m llama_cpp.server \
    --model "./${MODEL_FILE}" \
    --host "$HOST" \
    --port "$PORT" \
    --n_ctx "$CONTEXT_SIZE" \
    --n_gpu_layers "$GPU_LAYERS" \
    --verbose true

echo "--- Server started successfully. ---"