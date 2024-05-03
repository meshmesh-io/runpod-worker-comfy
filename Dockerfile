# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir xformers==0.0.21 \
    && pip3 install -r requirements.txt

# Install runpod
RUN pip3 install runpod requests
RUN pip3 install diffusers==0.26.2
RUN pip3 install -U peft transformers

# Download checkpoints/vae/LoRA to include in image
# RUN wget -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
# RUN wget -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors
# RUN wget -O models/vae/sdxl-vae-fp16-fix.safetensors https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors

RUN cd custom_nodes && \
    git clone https://github.com/frankchieng/ComfyUI_MagicClothing.git && \
    cd ComfyUI_MagicClothing && \
    pip3 install -r requirements.txt
    
RUN mkdir models/ipadapter

# Get MagicClothing models
RUN wget -O models/ipadapter/ip-adapter-faceid_sd15.bin https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid_sd15.bin?download=true
RUN wget -O models/loras/ip-adapter-faceid_sd15_lora.safetensors https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid_sd15_lora.safetensors?download=true
RUN wget -O custom_nodes/ComfyUI_MagicClothing/checkpoints/magic_clothing_768_vitonhd_joint.safetensors https://huggingface.co/ShineChen1024/MagicClothing/resolve/main/magic_clothing_768_vitonhd_joint.safetensors?download=true
RUN wget -O custom_nodes/ComfyUI_MagicClothing/checkpoints/cloth_segm.pth https://huggingface.co/ShineChen1024/MagicClothing/resolve/main/cloth_segm.pth?download=true
RUN mkdir custom_nodes/ComfyUI_MagicClothing/checkpoints/stable_ckpt
RUN wget -O custom_nodes/ComfyUI_MagicClothing/checkpoints/stable_ckpt/garment_extractor.safetensors https://huggingface.co/ShineChen1024/MagicClothing/resolve/main/stable_ckpt/garment_extractor.safetensors?download=true
RUN wget -O custom_nodes/ComfyUI_MagicClothing/checkpoints/stable_ckpt/ip_layer.pth https://huggingface.co/ShineChen1024/MagicClothing/resolve/main/stable_ckpt/ip_layer.pth?download=true

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
