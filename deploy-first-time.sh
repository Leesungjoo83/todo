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

# .env 파일이 없으면 생성
if [ ! -f ".env" ]; then
    # 먼저 원본 폴더(todo_AWS)에서 .env 파일 찾기
    SOURCE_ENV="${HOME}/todo_AWS/.env"
    if [ -f "$SOURCE_ENV" ]; then
        log_info "원본 폴더에서 .env 파일을 발견했습니다: $SOURCE_ENV"
        log_info ".env 파일을 복사합니다..."
        cp "$SOURCE_ENV" ".env"
        chmod 600 .env
        log_info "✅ 원본 폴더에서 .env 파일 복사 완료"
    elif [ -f "env.example" ]; then
        log_info "env.example을 기반으로 .env 파일을 생성합니다..."
        cp env.example .env
        log_info "✅ .env 파일 생성 완료"
        log_warn "⚠️  .env 파일을 생성했습니다. 반드시 수정하여 실제 데이터베이스 정보를 입력하세요!"
        echo ""
        log_info "필수 환경변수:"
        log_info "  - DB_HOST: RDS 엔드포인트 또는 localhost"
        log_info "  - DB_PORT: 3307 (기본값)"
        log_info "  - DB_USER: 데이터베이스 사용자명"
        log_info "  - DB_PASSWORD: 데이터베이스 비밀번호"
        log_info "  - DB_NAME: todo (기본값)"
        echo ""
        log_info "편집 명령어: nano .env"
        read -p ".env 파일을 지금 편집하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nano .env
        else
            log_warn "⚠️  .env 파일을 수동으로 편집해야 합니다!"
            log_info "다음 명령어로 편집: nano .env"
            read -p "계속하시겠습니까? (Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                log_error "배포가 취소되었습니다. .env 파일을 설정한 후 다시 실행하세요."
                exit 1
            fi
        fi
    else
        log_error "env.example 파일이 없습니다."
        log_error "필수: .env 파일을 생성하세요."
        log_info ".env 파일 예시:"
        echo "PORT=3000"
        echo "DB_HOST=your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com"
        echo "DB_PORT=3307"
        echo "DB_USER=root"
        echo "DB_PASSWORD=your_password"
        echo "DB_NAME=todo"
        echo "DB_CONNECTION_LIMIT=5"
        exit 1
    fi
else
    log_info "✅ .env 파일이 이미 존재합니다."
fi

# .env 파일 존재 확인 (필수)
if [ ! -f ".env" ]; then
    log_error ".env 파일이 없습니다. 배포를 계속할 수 없습니다."
    exit 1
fi

# .env 파일 필수 변수 확인
log_info ".env 파일의 필수 변수 확인 중..."

# .env 파일 읽기 및 검증
source .env 2>/dev/null || true

REQUIRED_VARS=("DB_HOST" "DB_USER" "DB_PASSWORD" "DB_NAME")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    value=$(grep "^${var}=" .env 2>/dev/null | cut -d'=' -f2- | tr -d ' ' || true)
    if [ -z "$value" ] || [ "$value" = "your_password_here" ] || [ "$value" = "your-database-instance" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_warn "⚠️  다음 환경변수가 설정되지 않았거나 기본값입니다:"
    for var in "${MISSING_VARS[@]}"; do
        log_warn "  - $var"
    done
    log_warn "데이터베이스 연결에 실패할 수 있습니다."
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "배포가 취소되었습니다. .env 파일을 수정한 후 다시 실행하세요."
        exit 1
    fi
else
    log_info "✅ 필수 환경변수 확인 완료"
fi

# .env 파일 권한 확인
chmod 600 .env 2>/dev/null || true
log_info "✅ .env 파일 권한 설정 완료 (600)"

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

# 9. 포트 충돌 해결 및 애플리케이션 시작
log_step "9. 포트 충돌 해결 및 애플리케이션 시작"

# 포트 3000 사용 여부 확인
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

# 기존 PM2 프로세스 확인
if pm2 list | grep -q "$APP_NAME"; then
    log_info "기존 PM2 프로세스를 정리합니다..."
    pm2 stop "$APP_NAME" 2>/dev/null || true
    pm2 delete "$APP_NAME" 2>/dev/null || true
    sleep 1
fi

# 포트를 사용하는 프로세스 종료
if [ "$PORT_IN_USE" = true ]; then
    log_warn "포트 3000이 사용 중입니다. 기존 프로세스를 종료합니다..."
    if command -v lsof &> /dev/null; then
        PORT_PID=$(lsof -ti:3000 2>/dev/null || true)
        if [ -n "$PORT_PID" ]; then
            kill -9 $PORT_PID 2>/dev/null || true
            sleep 2
        fi
    elif command -v ss &> /dev/null; then
        PORT_PID=$(ss -ltnp 2>/dev/null | grep ':3000' | awk '{print $6}' | cut -d, -f2 | cut -d= -f2 | head -1 || true)
        if [ -n "$PORT_PID" ] && [ "$PORT_PID" != "-" ]; then
            kill -9 $PORT_PID 2>/dev/null || true
            sleep 2
        fi
    fi
    log_info "✅ 포트 정리 완료"
fi

# .env 파일 최종 확인
log_info ".env 파일 최종 확인 중..."
if [ ! -f ".env" ]; then
    log_error ".env 파일이 없습니다. 애플리케이션을 시작할 수 없습니다."
    exit 1
fi

# 애플리케이션 시작 (.env 파일 사용)
log_info "새로운 프로세스를 시작합니다 (.env 파일 사용)..."
log_info "환경변수 파일: .env"

# PM2가 .env 파일을 자동으로 로드하도록 시작
pm2 start server.js --name "$APP_NAME" --update-env --env production 2>/dev/null || \
pm2 start server.js --name "$APP_NAME" --update-env

# PM2 저장
pm2 save

# 잠시 대기
sleep 3

# 10. 상태 확인
log_step "10. 배포 상태 확인"
pm2 status

# 11. 헬스 체크
log_step "11. 헬스 체크 및 환경변수 확인"
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
    log_warn "⚠️  애플리케이션이 응답하지 않을 수 있습니다."
    log_info "로그를 확인하세요: pm2 logs $APP_NAME"
    log_info ".env 파일을 확인하세요: cat .env"
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

