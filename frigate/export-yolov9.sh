#!/usr/bin/env bash
# Repo:   frigate/export-yolov9.sh
# Run on: the Docker VM, as root (Chapter 9). Needs Docker with BuildKit.
# Exports YOLOv9-t at 320x320 to ONNX with the YOLOv9 reference code
# (github.com/WongKinYiu/yolov9, GPL-3.0) in a disposable build.
# Follows the recipe in Frigate's documentation - check it for changes.
set -euo pipefail
MODEL_SIZE="${MODEL_SIZE:-t}"
IMG_SIZE="${IMG_SIZE:-320}"
DEST=/opt/frigate/config/model_cache
WORK="$(mktemp -d)"
cd "$WORK"

docker build . --build-arg MODEL_SIZE="$MODEL_SIZE" \
  --build-arg IMG_SIZE="$IMG_SIZE" --output . -f- <<'EOF'
FROM python:3.11 AS build
RUN apt-get update \
 && apt-get install --no-install-recommends -y libgl1 \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /yolov9
ADD https://github.com/WongKinYiu/yolov9.git .
RUN pip install --no-cache-dir -r requirements.txt \
 && pip install --no-cache-dir onnx onnxruntime "onnx-simplifier>=0.4.1"
ARG MODEL_SIZE
ARG IMG_SIZE
ADD https://github.com/WongKinYiu/yolov9/releases/download/v0.1/yolov9-${MODEL_SIZE}-converted.pt yolov9-${MODEL_SIZE}.pt
RUN sed -i "s/map_location='cpu')/map_location='cpu', weights_only=False)/g" \
    models/experimental.py
RUN python3 export.py --weights ./yolov9-${MODEL_SIZE}.pt \
    --imgsz ${IMG_SIZE} --simplify --include onnx
FROM scratch
ARG MODEL_SIZE
ARG IMG_SIZE
COPY --from=build /yolov9/yolov9-${MODEL_SIZE}.onnx /yolov9-${MODEL_SIZE}-${IMG_SIZE}.onnx
EOF

mkdir -p "$DEST"
mv "yolov9-${MODEL_SIZE}-${IMG_SIZE}.onnx" "$DEST/"
ls -lh "$DEST/yolov9-${MODEL_SIZE}-${IMG_SIZE}.onnx"
rm -rf "$WORK"
