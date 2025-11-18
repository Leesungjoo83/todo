#!/bin/bash

# Todo 애플리케이션 자동 배포 스크립트
# 사용법: ./deploy.sh

set -e  # 오류 발생 시 스크립트 중단

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 프로젝트 디렉토리 확인
PROJECT_DIR="${HOME}/todo-app"
APP_NAME="todo-app"

log_info "🚀 Todo 애플리케이션 배포를 시작합니다..."

# 프로젝트 디렉토리로 이동
if [ ! -d "$PROJECT_DIR" ]; then
    log_error "프로젝트 디렉토리를 찾을 수 없습니다: $PROJECT_DIR"
    log_info "프로젝트 디렉토리를 생성하거나 경로를 확인하세요."
    exit 1
fi

cd "$PROJECT_DIR"
log_info "프로젝트 디렉토리로 이동: $PROJECT_DIR"

# .env 파일 확인 (필수)
if [ ! -f ".env" ]; then
    log_error ".env 파일이 없습니다!"
    if [ -f "env.example" ]; then
        log_info "env.example을 기반으로 .env 파일을 생성합니다..."
        cp env.example .env
        chmod 600 .env
        log_warn "⚠️  .env 파일을 생성했습니다. 반드시 수정하여 실제 데이터베이스 정보를 입력하세요!"
        log_info "편집 명령어: nano .env"
        log_error "배포를 계속할 수 없습니다. .env 파일을 설정한 후 다시 실행하세요."
        exit 1
    else
        log_error ".env 파일이 없습니다. 배포를 계속할 수 없습니다."
        exit 1
    fi
else
    log_info "✅ .env 파일 확인 완료"
    # .env 파일 권한 확인
    chmod 600 .env 2>/dev/null || true
fi

# Git 저장소 확인
if [ -d ".git" ]; then
    log_info "📥 Git에서 최신 코드를 가져옵니다..."
    git fetch origin
    git pull origin main || git pull origin master
    log_info "✅ Git 업데이트 완료"
else
    log_warn ".git 디렉토리가 없습니다. Git 업데이트를 건너뜁니다."
fi

# Node.js 버전 확인
log_info "Node.js 버전 확인..."
node_version=$(node --version)
npm_version=$(npm --version)
log_info "Node.js: $node_version"
log_info "npm: $npm_version"

# 의존성 설치
log_info "📦 의존성을 설치합니다..."
npm install --production
log_info "✅ 의존성 설치 완료"

# PM2 설치 확인 및 설치
if ! command -v pm2 &> /dev/null; then
    log_warn "PM2가 설치되어 있지 않습니다. 설치합니다..."
    sudo npm install -g pm2
    log_info "✅ PM2 설치 완료"
else
    pm2_version=$(pm2 --version)
    log_info "PM2 버전: $pm2_version"
fi

# 포트 3000 충돌 해결
log_info "🔍 포트 3000 사용 여부 확인 중..."

# 포트 3000을 사용하는 프로세스 확인
PORT_IN_USE=false
if command -v lsof &> /dev/null; then
    if lsof -ti:3000 &> /dev/null; then
        PORT_IN_USE=true
    fi
elif command -v ss &> /dev/null; then
    if ss -ltnp | grep -q ':3000'; then
        PORT_IN_USE=true
    fi
elif command -v netstat &> /dev/null; then
    if netstat -tlnp 2>/dev/null | grep -q ':3000'; then
        PORT_IN_USE=true
    fi
fi

# PM2 프로세스가 실행 중인지 확인
PM2_RUNNING=false
if pm2 list | grep -q "$APP_NAME"; then
    PM2_RUNNING=true
fi

# 포트 충돌 해결
if [ "$PORT_IN_USE" = true ] || [ "$PM2_RUNNING" = true ]; then
    log_warn "포트 3000이 사용 중이거나 PM2 프로세스가 실행 중입니다."
    log_info "기존 프로세스를 정리합니다..."
    
    # PM2 프로세스 중지 및 삭제
    if [ "$PM2_RUNNING" = true ]; then
        pm2 stop "$APP_NAME" 2>/dev/null || true
        pm2 delete "$APP_NAME" 2>/dev/null || true
        log_info "✅ PM2 프로세스 정리 완료"
        sleep 1
    fi
    
    # 포트를 사용하는 다른 프로세스 종료
    if [ "$PORT_IN_USE" = true ]; then
        if command -v lsof &> /dev/null; then
            PORT_PID=$(lsof -ti:3000 2>/dev/null || true)
            if [ -n "$PORT_PID" ]; then
                log_info "포트 3000을 사용하는 프로세스 종료: PID $PORT_PID"
                kill -9 $PORT_PID 2>/dev/null || true
                sleep 2
            fi
        elif command -v ss &> /dev/null; then
            PORT_PID=$(ss -ltnp 2>/dev/null | grep ':3000' | awk '{print $6}' | cut -d, -f2 | cut -d= -f2 | head -1 || true)
            if [ -n "$PORT_PID" ] && [ "$PORT_PID" != "-" ]; then
                log_info "포트 3000을 사용하는 프로세스 종료: PID $PORT_PID"
                kill -9 $PORT_PID 2>/dev/null || true
                sleep 2
            fi
        elif command -v netstat &> /dev/null; then
            PORT_PID=$(netstat -tlnp 2>/dev/null | grep ':3000' | awk '{print $7}' | cut -d/ -f1 | head -1 || true)
            if [ -n "$PORT_PID" ] && [ "$PORT_PID" != "-" ]; then
                log_info "포트 3000을 사용하는 프로세스 종료: PID $PORT_PID"
                kill -9 $PORT_PID 2>/dev/null || true
                sleep 2
            fi
        fi
    fi
fi

# .env 파일 최종 확인
log_info ".env 파일 최종 확인 중..."
if [ ! -f ".env" ]; then
    log_error ".env 파일이 없습니다. 애플리케이션을 시작할 수 없습니다."
    exit 1
fi

# PM2로 애플리케이션 재시작 (.env 파일 사용)
log_info "🔄 애플리케이션을 시작합니다 (.env 파일 사용)..."
log_info "환경변수 파일: .env"

# PM2가 .env 파일을 자동으로 로드하도록 시작
pm2 start server.js --name "$APP_NAME" --update-env --env production 2>/dev/null || \
pm2 start server.js --name "$APP_NAME" --update-env

# 자동 시작 설정
pm2 save

# 잠시 대기 (애플리케이션 시작 시간)
sleep 3

# 배포 상태 확인
log_info "📊 배포 상태를 확인합니다..."
pm2 status

# 헬스 체크 및 환경변수 확인
log_info "🏥 애플리케이션 헬스 체크 및 환경변수 확인..."
sleep 2

# 환경변수 로드 확인
log_info "환경변수 로드 확인 중..."
if node -e "require('dotenv').config(); console.log('DB_HOST:', process.env.DB_HOST || 'NOT SET')" 2>/dev/null | grep -q "NOT SET"; then
    log_warn "⚠️  환경변수가 제대로 로드되지 않을 수 있습니다."
else
    log_info "✅ 환경변수 로드 확인 완료"
fi

# API 헬스 체크
if curl -s http://localhost:3000/api/todos > /dev/null; then
    log_info "✅ 애플리케이션이 정상적으로 응답합니다!"
else
    log_warn "⚠️  애플리케이션이 응답하지 않을 수 있습니다. 로그를 확인하세요."
    log_info ".env 파일을 확인하세요: cat .env"
fi

# 최근 로그 출력
log_info "📋 최근 로그 (최근 20줄):"
pm2 logs "$APP_NAME" --lines 20 --nostream

log_info "✅ 배포가 완료되었습니다!"
log_info "상세한 로그는 다음 명령어로 확인할 수 있습니다:"
log_info "  pm2 logs $APP_NAME"
log_info "실시간 로그:"
log_info "  pm2 logs $APP_NAME --lines 50"
log_info "모니터링:"
log_info "  pm2 monit"

