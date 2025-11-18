#!/bin/bash

# Todo 애플리케이션 첫 배포 스크립트
# 사용법: ./deploy-first-time.sh [git-repository-url]

set -e  # 오류 발생 시 스크립트 중단

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}[STEP]${NC} $1"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 프로젝트 디렉토리 설정
PROJECT_DIR="${HOME}/todo-app"
APP_NAME="todo-app"
GIT_REPO="${1:-https://github.com/Leesungjoo83/todo.git}"

log_info "🚀 Todo 애플리케이션 첫 배포를 시작합니다..."
log_info "프로젝트 디렉토리: $PROJECT_DIR"
log_info "Git 저장소: $GIT_REPO"

# 1. Node.js 및 npm 확인
log_step "1. Node.js 및 npm 확인"
if ! command -v node &> /dev/null; then
    log_error "Node.js가 설치되어 있지 않습니다."
    log_info "Node.js를 먼저 설치하세요."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    log_error "npm이 설치되어 있지 않습니다."
    log_info "npm을 먼저 설치하세요."
    exit 1
fi

node_version=$(node --version)
npm_version=$(npm --version)
log_info "✅ Node.js: $node_version"
log_info "✅ npm: $npm_version"

# 2. Git 확인
log_step "2. Git 확인"
if ! command -v git &> /dev/null; then
    log_error "Git이 설치되어 있지 않습니다."
    log_info "Git을 먼저 설치하세요: sudo apt-get install git"
    exit 1
fi
log_info "✅ Git 설치 확인"

# 3. 프로젝트 디렉토리 준비
log_step "3. 프로젝트 디렉토리 준비"
if [ -d "$PROJECT_DIR" ]; then
    log_warn "프로젝트 디렉토리가 이미 존재합니다: $PROJECT_DIR"
    read -p "기존 디렉토리를 삭제하고 다시 클론하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "기존 디렉토리를 삭제합니다..."
        rm -rf "$PROJECT_DIR"
        mkdir -p "$PROJECT_DIR"
    else
        log_info "기존 디렉토리를 사용합니다."
    fi
else
    mkdir -p "$PROJECT_DIR"
    log_info "✅ 프로젝트 디렉토리 생성: $PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# 4. Git에서 프로젝트 클론
log_step "4. Git에서 프로젝트 클론"
if [ ! -d ".git" ]; then
    log_info "Git 저장소를 클론합니다..."
    git clone "$GIT_REPO" .
    log_info "✅ Git 클론 완료"
else
    log_info "Git 저장소가 이미 존재합니다. 업데이트합니다..."
    git fetch origin
    git pull origin main || git pull origin master
    log_info "✅ Git 업데이트 완료"
fi

# 5. .env 파일 설정
log_step "5. .env 파일 설정"
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        log_info "env.example을 기반으로 .env 파일을 생성합니다..."
        cp env.example .env
        log_warn "⚠️  .env 파일을 생성했습니다. 반드시 수정하여 실제 데이터베이스 정보를 입력하세요!"
        log_info "편집 명령어: nano .env"
        read -p ".env 파일을 지금 편집하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nano .env
        fi
    else
        log_error "env.example 파일이 없습니다."
        log_warn ".env 파일을 수동으로 생성하세요."
    fi
else
    log_info "✅ .env 파일이 이미 존재합니다."
fi

# 6. 의존성 설치
log_step "6. 의존성 설치"
log_info "npm 패키지를 설치합니다..."
npm install --production
log_info "✅ 의존성 설치 완료"

# 7. PM2 설치
log_step "7. PM2 설치"
if ! command -v pm2 &> /dev/null; then
    log_info "PM2를 설치합니다..."
    sudo npm install -g pm2
    log_info "✅ PM2 설치 완료"
else
    pm2_version=$(pm2 --version)
    log_info "✅ PM2가 이미 설치되어 있습니다. 버전: $pm2_version"
fi

# 8. PM2 자동 시작 설정
log_step "8. PM2 자동 시작 설정"
log_info "PM2 자동 시작을 설정합니다..."
startup_output=$(pm2 startup)
log_info "다음 명령어를 실행하세요 (sudo 권한 필요):"
echo "$startup_output" | grep "sudo"

# 9. 애플리케이션 시작
log_step "9. 애플리케이션 시작"
if pm2 list | grep -q "$APP_NAME"; then
    log_info "기존 프로세스를 재시작합니다..."
    pm2 restart "$APP_NAME" --update-env
else
    log_info "새로운 프로세스를 시작합니다..."
    pm2 start server.js --name "$APP_NAME" --update-env
fi

# PM2 저장
pm2 save

# 잠시 대기
sleep 3

# 10. 상태 확인
log_step "10. 배포 상태 확인"
pm2 status

# 11. 헬스 체크
log_step "11. 헬스 체크"
sleep 2
if curl -s http://localhost:3000/api/todos > /dev/null; then
    log_info "✅ 애플리케이션이 정상적으로 응답합니다!"
else
    log_warn "⚠️  애플리케이션이 응답하지 않을 수 있습니다."
    log_info "로그를 확인하세요: pm2 logs $APP_NAME"
fi

# 12. 최근 로그 출력
log_step "12. 최근 로그"
log_info "최근 로그 (최근 20줄):"
pm2 logs "$APP_NAME" --lines 20 --nostream

# 완료 메시지
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ 첫 배포가 완료되었습니다!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "📋 유용한 명령어:"
log_info "  pm2 status              - 프로세스 상태 확인"
log_info "  pm2 logs $APP_NAME      - 로그 확인"
log_info "  pm2 logs $APP_NAME --lines 50 - 최근 50줄 로그"
log_info "  pm2 monit               - 실시간 모니터링"
log_info "  pm2 restart $APP_NAME   - 애플리케이션 재시작"
log_info "  pm2 stop $APP_NAME      - 애플리케이션 중지"
log_info "  ./deploy.sh             - 다음 배포 (빠른 배포)"
echo ""
log_warn "⚠️  중요: PM2 자동 시작 설정을 완료하세요!"
log_info "위에서 출력된 sudo 명령어를 실행하세요."

