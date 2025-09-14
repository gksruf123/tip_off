#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-gksruf123/tipoff-gui:latest}"
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${DOCKERFILE:-$APP_ROOT/Dockerfile}"
CONF_DIR_HOST="${CONF_DIR_HOST:-$HOME/.tipoff-docker}"
LAUNCHER_SYS="$HOME/.local/share/applications/tipoff-docker.desktop"
LAUNCHER_DESK="$HOME/Desktop/tipoff-docker.desktop"

# 실행권한 정리
chmod +x "$APP_ROOT/entrypoint.sh" 2>/dev/null || true
chmod +x "$APP_ROOT/run-tipoff-gui.sh" 2>/dev/null || true
chmod +x "$APP_ROOT/install-tipoff-docker.sh" 2>/dev/null || true

# X 권한
command -v xhost >/dev/null 2>&1 && xhost +local: || true

# 설정 폴더
mkdir -p "$CONF_DIR_HOST"

# 이미지 준비(로컬 빌드 or pull). 로컬 Dockerfile 있으면 빌드, 아니면 pull만.
if [ -f "$DOCKERFILE" ]; then
  echo "[+] docker build -t $IMAGE -f $DOCKERFILE $APP_ROOT"
  docker build -t "$IMAGE" -f "$DOCKERFILE" "$APP_ROOT"
else
  echo "[+] docker pull $IMAGE"
  docker pull "$IMAGE"
fi

# XDG_RUNTIME_DIR 추정
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"

# 1회 실행(테스트)
docker rm -f tipoff_gui >/dev/null 2>&1 || true
docker run --rm -d \
  --name tipoff_gui \
  --net=host \
  -e DISPLAY \
  -e XDG_RUNTIME_DIR \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus" \
  -e TZ="Asia/Seoul" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "${XDG_RUNTIME_DIR}:${XDG_RUNTIME_DIR}" \
  -v "${CONF_DIR_HOST}":/home/appuser/.tipoff \
  "$IMAGE"

echo "[+] TIP-OFF (Docker) started. Container: tipoff_gui"

# 메뉴용 런처 생성
mkdir -p "$(dirname "$LAUNCHER_SYS")"
cat > "$LAUNCHER_SYS" <<EOF
[Desktop Entry]
Type=Application
Name=TIP-OFF (Docker)
Comment=Run TIP-OFF in Docker
Exec=/usr/bin/env bash -lc 'command -v xhost >/dev/null 2>&1 && xhost +local: || true; : \${XDG_RUNTIME_DIR:=/run/user/\$(id -u)}; docker start tipoff_gui >/dev/null 2>&1 || docker run --rm -d --name tipoff_gui --net=host -e DISPLAY -e XDG_RUNTIME_DIR -e DBUS_SESSION_BUS_ADDRESS=unix:path=\${XDG_RUNTIME_DIR}/bus -e TZ=Asia/Seoul -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v "\${XDG_RUNTIME_DIR}:\${XDG_RUNTIME_DIR}" -v "$CONF_DIR_HOST":/home/appuser/.tipoff "$IMAGE"; sleep 0.2'
Icon=utilities-terminal
Terminal=false
Categories=Network;Utility;
EOF
chmod +x "$LAUNCHER_SYS"

# 라즈베리파이/일반 데스크톱 바탕화면에도 복사(있으면 갱신)
if [ -d "$HOME/Desktop" ]; then
  cp -f "$LAUNCHER_SYS" "$LAUNCHER_DESK"
  chmod +x "$LAUNCHER_DESK"
fi

echo "[✓] 설치 완료: 앱 메뉴 또는 바탕화면의 'TIP-OFF (Docker)' 아이콘으로 실행하세요."
