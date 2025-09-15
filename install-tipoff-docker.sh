#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-gksruf123/tipoff-gui:latest}"
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${DOCKERFILE:-$APP_ROOT/Dockerfile}"
CONF_DIR_HOST="${CONF_DIR_HOST:-$HOME/.tipoff-docker}"
LAUNCHER_SYS="$HOME/.local/share/applications/tipoff-docker.desktop"
LAUNCHER_DESK="$HOME/Desktop/tipoff-docker.desktop"

chmod +x "$APP_ROOT/entrypoint.sh" 2>/dev/null || true
chmod +x "$APP_ROOT/run-tipoff-gui.sh" 2>/dev/null || true
chmod +x "$APP_ROOT/install-tipoff-docker.sh" 2>/dev/null || true

command -v xhost >/dev/null 2>&1 && xhost +local: || true
mkdir -p "$CONF_DIR_HOST"

# 로컬 Dockerfile 있으면 빌드, 없으면 pull
if [ -f "$DOCKERFILE" ]; then
  docker build -t "$IMAGE" -f "$DOCKERFILE" "$APP_ROOT"
else
  docker pull "$IMAGE"
fi

: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"

docker rm -f tipoff_gui >/dev/null 2>&1 || true
docker run --rm -d \
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
  "$IMAGE"

# 아이콘 파일 복사
ICON_SRC="$APP_ROOT/assets/tipoff.png"
ICON_DST="$HOME/.local/share/icons/tipoff.png"
mkdir -p "$(dirname "$ICON_DST")"
cp -f "$ICON_SRC" "$ICON_DST"

mkdir -p "$(dirname "$LAUNCHER_SYS")"
cat > "$LAUNCHER_SYS" <<EOF
[Desktop Entry]
Type=Application
Name=TIP-OFF (Docker)
Comment=Run TIP-OFF in Docker
Exec=/usr/bin/env bash -lc 'command -v xhost >/dev/null 2>&1 && xhost +local: || true; : \${XDG_RUNTIME_DIR:=/run/user/\$(id -u)}; docker start tipoff_gui >/dev/null 2>&1 || docker run --rm -d --name tipoff_gui --net=host -e DISPLAY -e XDG_RUNTIME_DIR -e DBUS_SESSION_BUS_ADDRESS=unix:path=\${XDG_RUNTIME_DIR}/bus -e GTK_IM_MODULE=ibus -e QT_IM_MODULE=ibus -e XMODIFIERS=@im=ibus -e TZ=Asia/Seoul -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v "\${XDG_RUNTIME_DIR}/bus:\${XDG_RUNTIME_DIR}/bus" -v "$CONF_DIR_HOST":/home/appuser/.tipoff "$IMAGE"; sleep 0.2'
Icon=$ICON_DST
Terminal=false
Categories=Network;Utility;
EOF
chmod +x "$LAUNCHER_SYS"

# 바탕화면에도 복사(있으면 갱신)
if [ -d "$HOME/Desktop" ]; then
  cp -f "$LAUNCHER_SYS" "$LAUNCHER_DESK"
  chmod +x "$LAUNCHER_DESK"
fi

echo "[✓] 설치 완료: 앱 메뉴 또는 바탕화면의 'TIP-OFF (Docker)' 아이콘으로 실행하세요."
