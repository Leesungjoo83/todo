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

# .env 파일 확인
if [ ! -f ".env" ]; then
    log_warn ".env 파일이 없습니다. env.example을 참고하여 생성하세요."
    log_warn "배포를 계속하지만 환경변수가 설정되지 않을 수 있습니다."
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

# PM2로 애플리케이션 재시작
log_info "🔄 애플리케이션을 재시작합니다..."

# PM2 프로세스가 실행 중인지 확인
if pm2 list | grep -q "$APP_NAME"; then
    log_info "기존 프로세스를 재시작합니다..."
    pm2 restart "$APP_NAME" --update-env
else
    log_info "새로운 프로세스를 시작합니다..."
    pm2 start server.js --name "$APP_NAME" --update-env
    # 자동 시작 설정 (처음 한 번만)
    log_info "자동 시작 설정을 확인합니다..."
    pm2 save
fi

# 잠시 대기 (애플리케이션 시작 시간)
sleep 3

# 배포 상태 확인
log_info "📊 배포 상태를 확인합니다..."
pm2 status

# 헬스 체크
log_info "🏥 애플리케이션 헬스 체크..."
sleep 2

if curl -s http://localhost:3000/api/todos > /dev/null; then
    log_info "✅ 애플리케이션이 정상적으로 응답합니다!"
else
    log_warn "⚠️  애플리케이션이 응답하지 않을 수 있습니다. 로그를 확인하세요."
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

