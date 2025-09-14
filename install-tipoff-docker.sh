#!/usr/bin/env bash
set -euo pipefail

# ========= 설정 =========
IMAGE="${IMAGE:-gksruf123/tipoff-gui:dev}"   # 원하면 레지스트리/태그 바꿔도 됨
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${DOCKERFILE:-$APP_ROOT/Dockerfile}"
CONF_DIR_HOST="${CONF_DIR_HOST:-$HOME/.tipoff-docker}"   # 네이티브와 분리
CREATE_LAUNCHER="${CREATE_LAUNCHER:-1}"                  # 1이면 런처 생성 시도
LAUNCHER_NAME="${LAUNCHER_NAME:-TIP-OFF (Docker)}"
LAUNCHER_FILE="$HOME/.local/share/applications/tipoff-docker.desktop"

# ========= 1) 실행권한 부여 =========
echo "[+] grant executable bits"
chmod +x "$APP_ROOT/entrypoint.sh" 2>/dev/null || true
chmod +x "$APP_ROOT/run-tipoff-gui.sh" 2>/dev/null || true
chmod +x "$APP_ROOT/install-tipoff-native.sh" 2>/dev/null || true
chmod +x "$APP_ROOT/install-tipoff-docker.sh" 2>/dev/null || true

# ========= 2) X 권한 (X11) =========
if command -v xhost >/dev/null 2>&1; then
  echo "[+] xhost +local:"
  xhost +local: || true
fi

# ========= 3) 설정 디렉토리 준비 =========
mkdir -p "$CONF_DIR_HOST"

# ========= 4) 이미지 빌드 =========
echo "[+] docker build -t $IMAGE -f $DOCKERFILE $APP_ROOT"
docker build -t "$IMAGE" -f "$DOCKERFILE" "$APP_ROOT"

# ========= 5) 컨테이너 실행(테스트) =========
echo "[+] docker run (host net, X11, config volume)"
set +e
docker rm -f tipoff_gui >/dev/null 2>&1
set -e

docker run --rm -d \
  --name tipoff_gui \
  --net=host \
  -e DISPLAY \
  -e XDG_RUNTIME_DIR \
  -e TZ="Asia/Seoul" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "$CONF_DIR_HOST":/home/appuser/.tipoff \
  "$IMAGE"

echo "[+] TIP-OFF (Docker) started. Container: tipoff_gui"

# ========= 6) 데스크톱 런처(옵션) =========
if [ "$CREATE_LAUNCHER" = "1" ]; then
  mkdir -p "$(dirname "$LAUNCHER_FILE")"
  cat > "$LAUNCHER_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$LAUNCHER_NAME
Comment=Run TIP-OFF in Docker
Exec=bash -lc 'command -v xhost >/dev/null 2>&1 && xhost +local: || true; docker start tipoff_gui >/dev/null 2>&1 || docker run --rm -d --name tipoff_gui --net=host -e DISPLAY -e XDG_RUNTIME_DIR -e TZ=Asia/Seoul -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v "$CONF_DIR_HOST":/home/appuser/.tipoff "$IMAGE"; sleep 0.3'
Icon=utilities-terminal
Terminal=false
Categories=Network;Utility;
EOF
  chmod +x "$LAUNCHER_FILE"
  echo "[+] Desktop launcher created: $LAUNCHER_FILE"
fi

echo "[✓] Done. GUI는 몇 초 내 떠야 합니다. 로그:  docker logs -f tipoff_gui"
echo "    중지:      docker stop tipoff_gui"
