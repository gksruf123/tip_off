#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-gksruf123/tipoff-gui:latest}"

# X 권한
command -v xhost >/dev/null 2>&1 && xhost +local: || true

# XDG_RUNTIME_DIR 기본값 보정
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"

# 설정 폴더
CONF_DIR_HOST="${CONF_DIR_HOST:-$HOME/.tipoff-docker}"
mkdir -p "$CONF_DIR_HOST"

# 기존 컨테이너 정리
docker rm -f tipoff_gui >/dev/null 2>&1 || true

# 실행: X11 + DBus + IME env
exec docker run --rm -it \
  --name tipoff_gui \
  --net=host \
  -e DISPLAY \
  -e XDG_RUNTIME_DIR \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus" \
  -e GTK_IM_MODULE=ibus \
  -e QT_IM_MODULE=ibus \
  -e XMODIFIERS='@im=ibus' \
  -e TZ="Asia/Seoul" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "${XDG_RUNTIME_DIR}/bus:${XDG_RUNTIME_DIR}/bus" \
  -v "${CONF_DIR_HOST}":/home/appuser/.tipoff \
  "${IMAGE}"
