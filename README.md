# RunPod Deployment for Mixtral 8x7B GGUF (Q6_K)

This repository provides a complete setup to deploy the `TheBloke/dolphin-2.7-mixtral-8x7b-GGUF` model with `Q6_K` quantization on RunPod for maximum inference speed.

The server provides an OpenAI-compatible API.

## RunPod Setup

1.  **Navigate to Secure Cloud:** Log in to your RunPod account and go to the `Secure Cloud` dashboard.
2.  **Select a GPU Pod:** Choose a GPU pod with **1x NVIDIA H100 SXM 80GB**. This is a top-tier GPU and is crucial for loading the entire model onto the VRAM for the best performance.
3.  **Choose Template:** Set the template to **RunPod Pytorch 2.8.0**.
4.  **Set Disk Space:** Allocate at least **50 GB** for the Container Disk and **10 GB** for the Workspace Disk.
5.  **Deploy:** Click `Deploy` and wait for the pod to become active.

## Deployment Steps

1.  **Connect to Pod:** Once active, connect to your pod by clicking `Connect` and then `Start Web Terminal`.

2.  **Clone This Repository:** In the terminal, run the following command:
    ```bash
    git clone https://github.com/your-username/runpod-deployment.git
    cd runpod-deployment
    ```
    *(Note: You will need to create a GitHub repository and push these files to it first.)*

3.  **Make the Script Executable:**
    ```bash
    chmod +x start.sh
    ```

4.  **Run the Deployment Script:**
    ```bash
    ./start.sh
    ```
    *   **First-time setup:** The script will first download the 38.4 GB model file, which will take some time. After the download, it will install the required packages and start the server.
    *   **Subsequent runs:** The script will detect that the model is already downloaded and will start the server much faster.

## API Usage

The server runs on port `8000` and mimics the OpenAI API structure. You can use any OpenAI-compatible client or library to interact with it.

### Example: `curl` for Chat Completion

Once the server is running, you can open a new terminal in RunPod to get your pod's IP address or use the provided connection URLs.

```bash
curl http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d 
    "{
    "model": "dolphin-2.7-mixtral-8x7b",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant."
      },
      {
        "role": "user",
        "content": "What are the main advantages of using a multi-GPU setup for LLMs?"
      }
    ],
    "temperature": 0.7,
    "max_tokens": 512
  }"
```

