# GUI 클라이언트용
FROM python:3.11-slim

# 필수 OS 패키지 (Tk, X11, 로케일 등)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tk xauth x11-apps libx11-6 libxext6 libxrender1 libxft2 libxi6 \
    locales tzdata ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 로케일
RUN sed -i 's/# ko_KR.UTF-8/ko_KR.UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8 TZ=Asia/Seoul
ENV PYTHONUNBUFFERED=1

# (선택) 앱 전용 사용자
RUN useradd -m -u 1000 appuser
WORKDIR /home/appuser/app

# 파이썬 의존성
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스
COPY . .

# 컨테이너 내부의 기본 설정 디렉토리 (호스트 볼륨으로 덮어쓸 예정)
RUN mkdir -p /home/appuser/.tipoff && chown -R appuser:appuser /home/appuser

# 엔트리포인트
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER appuser
CMD ["/usr/local/bin/entrypoint.sh"]
