#!/bin/bash

# 포트 3000 충돌 해결 스크립트
# 사용법: ./fix-port-error.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

APP_NAME="todo"

log_info "🔧 포트 3000 충돌 문제를 해결합니다..."

# 1. PM2 프로세스 확인 및 중지
log_info "1. PM2 프로세스 확인 중..."
if pm2 list | grep -q "$APP_NAME"; then
    log_info "기존 PM2 프로세스를 중지합니다..."
    pm2 stop "$APP_NAME" || true
    pm2 delete "$APP_NAME" || true
    log_info "✅ PM2 프로세스 중지 완료"
else
    log_info "PM2에서 실행 중인 프로세스가 없습니다."
fi

# 2. 포트 3000을 사용하는 프로세스 확인 및 종료
log_info "2. 포트 3000을 사용하는 프로세스 확인 중..."
PORT_PID=$(lsof -ti:3000 2>/dev/null || ss -ltnp 2>/dev/null | grep ':3000' | awk '{print $6}' | cut -d, -f2 | cut -d= -f2 | head -1 || true)

if [ -n "$PORT_PID" ]; then
    log_warn "포트 3000을 사용하는 프로세스를 발견했습니다. PID: $PORT_PID"
    log_info "프로세스를 종료합니다..."
    kill -9 $PORT_PID 2>/dev/null || true
    sleep 2
    log_info "✅ 프로세스 종료 완료"
else
    log_info "포트 3000을 사용하는 프로세스가 없습니다."
fi

# 3. 추가 확인: netstat 또는 ss 사용
if command -v ss &> /dev/null; then
    PORT_CHECK=$(ss -ltnp | grep ':3000' | awk '{print $6}' | head -1 || true)
elif command -v netstat &> /dev/null; then
    PORT_CHECK=$(netstat -tlnp 2>/dev/null | grep ':3000' | awk '{print $7}' | cut -d/ -f1 | head -1 || true)
fi

if [ -n "$PORT_CHECK" ] && [ "$PORT_CHECK" != "$PORT_PID" ]; then
    log_warn "추가로 발견된 프로세스: $PORT_CHECK"
    kill -9 $PORT_CHECK 2>/dev/null || true
    sleep 2
fi

# 4. 포트 해제 확인
sleep 1
if command -v ss &> /dev/null; then
    FINAL_CHECK=$(ss -ltnp | grep ':3000' || true)
elif command -v netstat &> /dev/null; then
    FINAL_CHECK=$(netstat -tlnp 2>/dev/null | grep ':3000' || true)
fi

if [ -z "$FINAL_CHECK" ]; then
    log_info "✅ 포트 3000이 해제되었습니다!"
else
    log_warn "⚠️  포트 3000이 아직 사용 중일 수 있습니다."
    log_info "수동으로 확인하세요:"
    log_info "  sudo lsof -i :3000"
    log_info "  또는"
    log_info "  sudo ss -ltnp | grep :3000"
fi

# 5. PM2 프로세스 목록 확인
log_info "3. PM2 프로세스 목록 확인:"
pm2 list

log_info "✅ 포트 충돌 해결 완료!"
log_info ""
log_info "이제 애플리케이션을 다시 시작할 수 있습니다:"
log_info "  pm2 start server.js --name todo"
log_info "  또는"
log_info "  ./deploy.sh"

