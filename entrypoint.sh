#!/usr/bin/env bash
set -euo pipefail

# Wayland/X11 환경 변수는 호스트에서 전달받음
# 설정 디렉토리 확인(볼륨으로 마운트됨)
mkdir -p "/home/appuser/.tipoff"

# TIP-OFF GUI 진입
exec python -m app.main
