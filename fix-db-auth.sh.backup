#!/bin/bash

# 데이터베이스 인증 오류 해결 스크립트
# 사용법: ./fix-db-auth.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}[STEP]${NC} $1"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

APP_NAME="todo-app"
TODO_AWS_DIR="${HOME}/todo_AWS"
TODO_APP_DIR="${HOME}/todo-app"

log_info "🔧 데이터베이스 인증 오류 해결 스크립트"

# 1. 프로젝트 디렉토리 확인
log_step "1. 프로젝트 디렉토리 확인"

# todo-app 디렉토리 확인
if [ ! -d "$TODO_APP_DIR" ]; then
    log_error "todo-app 디렉토리를 찾을 수 없습니다: $TODO_APP_DIR"
    log_info "현재 작업 디렉토리에서 계속 진행합니다..."
    TODO_APP_DIR="$(pwd)"
fi

log_info "현재 디렉토리: $(pwd)"
log_info "todo-app 디렉토리: $TODO_APP_DIR"

# 2. .env 파일 확인 및 복사
log_step "2. .env 파일 확인 및 복사"

ENV_COPIED=false

# todo-app 폴더의 .env 확인
if [ -f "$TODO_APP_DIR/.env" ]; then
    log_info "✅ $TODO_APP_DIR/.env 파일 존재"
    log_info "현재 .env 파일 내용 (비밀번호 제외):"
    cat "$TODO_APP_DIR/.env" | grep -v PASSWORD | head -10
else
    log_warn "⚠️  $TODO_APP_DIR/.env 파일이 없습니다."
    
    # 원본 폴더에서 복사
    if [ -f "$TODO_AWS_DIR/.env" ]; then
        log_info "원본 폴더에서 .env 파일을 복사합니다: $TODO_AWS_DIR/.env"
        cp "$TODO_AWS_DIR/.env" "$TODO_APP_DIR/.env"
        chmod 600 "$TODO_APP_DIR/.env"
        ENV_COPIED=true
        log_info "✅ .env 파일 복사 완료"
    else
        log_error "원본 폴더에도 .env 파일이 없습니다: $TODO_AWS_DIR/.env"
        log_info ".env 파일을 수동으로 생성하세요:"
        log_info "  nano $TODO_APP_DIR/.env"
        exit 1
    fi
fi

# 3. .env 파일 검증
log_step "3. .env 파일 검증"

cd "$TODO_APP_DIR"

if [ ! -f ".env" ]; then
    log_error ".env 파일이 없습니다!"
    exit 1
fi

# 환경변수 읽기
source .env 2>/dev/null || true

DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-3307}
DB_USER=${DB_USER:-}
DB_PASSWORD=${DB_PASSWORD:-}
DB_NAME=${DB_NAME:-todo}

log_info "환경변수 확인:"
log_info "  DB_HOST: ${DB_HOST:-NOT SET}"
log_info "  DB_PORT: ${DB_PORT:-3307}"
log_info "  DB_USER: ${DB_USER:-NOT SET}"
log_info "  DB_NAME: ${DB_NAME:-todo}"
log_info "  DB_PASSWORD: ${DB_PASSWORD:+[설정됨]}"

# 필수 변수 확인
MISSING_VARS=()
if [ -z "$DB_HOST" ]; then MISSING_VARS+=("DB_HOST"); fi
if [ -z "$DB_USER" ]; then MISSING_VARS+=("DB_USER"); fi
if [ -z "$DB_PASSWORD" ]; then MISSING_VARS+=("DB_PASSWORD"); fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_error "다음 환경변수가 설정되지 않았습니다:"
    for var in "${MISSING_VARS[@]}"; do
        log_error "  - $var"
    done
    log_info ".env 파일을 수정하세요: nano $TODO_APP_DIR/.env"
    exit 1
fi

# 4. PM2 프로세스 확인 및 재시작
log_step "4. PM2 프로세스 재시작 (환경변수 반영)"

if pm2 list | grep -q "$APP_NAME"; then
    log_info "기존 PM2 프로세스를 중지합니다..."
    pm2 stop "$APP_NAME" 2>/dev/null || true
    pm2 delete "$APP_NAME" 2>/dev/null || true
    sleep 2
fi

# todo-app 폴더로 이동하여 시작
cd "$TODO_APP_DIR"

if [ ! -f "server.js" ]; then
    log_error "server.js 파일을 찾을 수 없습니다: $TODO_APP_DIR/server.js"
    exit 1
fi

log_info "PM2로 애플리케이션을 시작합니다..."
log_info "작업 디렉토리: $TODO_APP_DIR"
log_info ".env 파일: $TODO_APP_DIR/.env"

# PM2 시작 (.env 파일이 있는 디렉토리에서 실행)
pm2 start server.js --name "$APP_NAME" --update-env

pm2 save

sleep 3

# 5. 상태 확인
log_step "5. 상태 확인"

pm2 status

# 6. 로그 확인
log_step "6. 최근 로그 확인"
log_info "최근 에러 로그 (최근 20줄):"
pm2 logs "$APP_NAME" --err --lines 20 --nostream

log_info ""
log_info "최근 출력 로그 (최근 10줄):"
pm2 logs "$APP_NAME" --out --lines 10 --nostream

# 7. 연결 테스트
log_step "7. 연결 테스트"

sleep 2

if curl -s http://localhost:3000/api/todos > /dev/null 2>&1; then
    log_info "✅ 애플리케이션이 정상적으로 응답합니다!"
    log_info "API 테스트: curl http://localhost:3000/api/todos"
else
    log_warn "⚠️  애플리케이션이 아직 응답하지 않을 수 있습니다."
    log_info "로그를 확인하세요: pm2 logs $APP_NAME --lines 50"
fi

log_step "✅ 완료!"

log_info "다음 명령어로 로그를 확인하세요:"
log_info "  pm2 logs $APP_NAME --lines 50"
log_info "  pm2 logs $APP_NAME --err --lines 50  # 에러만"
log_info ""
log_info "환경변수가 여전히 로드되지 않으면:"
log_info "  1. .env 파일 확인: cat $TODO_APP_DIR/.env"
log_info "  2. PM2 완전히 재시작: pm2 delete $APP_NAME && pm2 start server.js --name $APP_NAME --update-env"
log_info "  3. RDS 보안 그룹에서 EC2 IP 허용 확인"

