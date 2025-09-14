#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-tipoff/gui:dev}"

# X 권한 (X11)
command -v xhost >/dev/null 2>&1 && xhost +local: || true

# 빌드
docker build -t "$IMAGE" -f Dockerfile .

# 실행
docker run --rm -it \
  --name tipoff_gui \
  --net=host \
  -e DISPLAY \
  -e XDG_RUNTIME_DIR \
  -e TZ="Asia/Seoul" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "$HOME/.tipoff-docker":/home/appuser/.tipoff \
  "$IMAGE"
