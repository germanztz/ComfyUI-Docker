# ComfyUI Docker Build File v1.0.1 by John Aldred
# https://www.johnaldred.com
# https://github.com/kaouthia

# Use a minimal Python base image (adjust version as needed)
FROM python:3.12-slim-bookworm

# Allow passing in your host UID/GID (defaults 1000:1000)
ARG UID=1000
ARG GID=1000
RUN groupadd --gid ${GID} appuser && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash appuser

# Install OS deps and create the non-root user
# Install Mesa/GL and GLib so OpenCV can load libGL.so.1 for ComfyUI-VideoHelperSuite
RUN apt-get update && apt-get install -y --no-install-recommends \
     git \
     libgl1 \
     libglx-mesa0 \
     libglib2.0-0 \
     fonts-dejavu-core \
     fontconfig \
     && rm -rf /var/lib/apt/lists/*

# Copy and enable the startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN mkdir /app && chown -R 1000:1000 /app 

# Switch to non-root user
USER $UID:$GID

# make ~/.local/bin available on the PATH so scripts like tqdm, torchrun, etc. are found
ENV PATH=/home/appuser/.local/bin:$PATH

# Set the working directory
WORKDIR /app

# Clone the ComfyUI repository (replace URL with the official repo)
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# Change directory to the ComfyUI folder
WORKDIR /app/ComfyUI

# Install ComfyUI dependencies
RUN pip install --update pip --no-cache-dir -r requirements.txt

# Run entrypoint first, then start ComfyUI
RUN /entrypoint.sh

# (Optional) Clean up pip cache to reduce image size
RUN pip cache purge

# Expose the port that ComfyUI will use (change if needed)
EXPOSE 8188

CMD ["python","/app/ComfyUI/main.py","--listen","0.0.0.0"]
