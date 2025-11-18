#!/bin/bash

# 원본 폴더에서 .env 파일을 클론본으로 복사하는 스크립트
# 사용법: ./copy-env.sh [원본_폴더] [대상_폴더]

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

# 기본 경로 설정
SOURCE_DIR="${1:-${HOME}/todo_AWS}"
TARGET_DIR="${2:-${HOME}/todo-app}"

log_info "🔍 .env 파일 복사 스크립트"
log_info "원본 폴더: $SOURCE_DIR"
log_info "대상 폴더: $TARGET_DIR"

# 원본 폴더 확인
if [ ! -d "$SOURCE_DIR" ]; then
    log_error "원본 폴더를 찾을 수 없습니다: $SOURCE_DIR"
    exit 1
fi

# 원본 .env 파일 확인
if [ ! -f "$SOURCE_DIR/.env" ]; then
    log_error "원본 폴더에 .env 파일이 없습니다: $SOURCE_DIR/.env"
    log_info "다른 위치를 찾아보세요:"
    log_info "  find ~ -name '.env' -type f 2>/dev/null | grep -i todo"
    exit 1
fi

log_info "✅ 원본 .env 파일 발견: $SOURCE_DIR/.env"

# 대상 폴더 확인 및 생성
if [ ! -d "$TARGET_DIR" ]; then
    log_warn "대상 폴더가 없습니다. 생성합니다: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

# 대상 폴더에 이미 .env 파일이 있는지 확인
if [ -f "$TARGET_DIR/.env" ]; then
    log_warn "대상 폴더에 이미 .env 파일이 있습니다: $TARGET_DIR/.env"
    read -p "덮어쓰시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "복사를 취소했습니다."
        exit 0
    fi
    log_info "기존 .env 파일을 백업합니다..."
    cp "$TARGET_DIR/.env" "$TARGET_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)"
fi

# .env 파일 복사
log_info ".env 파일을 복사합니다..."
cp "$SOURCE_DIR/.env" "$TARGET_DIR/.env"
chmod 600 "$TARGET_DIR/.env"

log_info "✅ .env 파일 복사 완료: $TARGET_DIR/.env"

# 복사된 파일 확인
log_info "복사된 파일 확인 (비밀번호 제외):"
cat "$TARGET_DIR/.env" | grep -v PASSWORD | head -10

log_info ""
log_info "✅ 복사 완료!"
log_info "대상 폴더로 이동: cd $TARGET_DIR"
log_info ".env 파일 편집: nano $TARGET_DIR/.env"

