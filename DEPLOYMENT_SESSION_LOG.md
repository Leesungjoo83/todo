# 배포 세션 로그

이 문서는 2025년 11월 18일 Todo 애플리케이션 AWS 배포 및 문제 해결 과정을 기록합니다.

## 📋 작업 요약

### 1. 문서 정리
- **README.md** 간소화: 프로젝트 소개와 빠른 시작만 포함
- **TROUBLESHOOTING.md** 통합: 
  - 기존 `TROUBLESHOOTING.md` (로컬 개발 환경)
  - `DEPLOY_TROUBLESHOOTING.md` (배포 문제)
  - `RDS_CONNECTION_GUIDE.md` (RDS 연결 문제)
  - 위 세 문서를 하나로 통합하여 체계적으로 재구성
- 중복 파일 삭제:
  - `DEPLOY_TROUBLESHOOTING.md` 삭제
  - `RDS_CONNECTION_GUIDE.md` 삭제
- 문서 간 링크 업데이트

### 2. 외부 접속 문제 해결

#### 문제
- 브라우저에서 `http://52.79.226.150:3000` 접속 시 "Failed to fetch" 오류
- 로컬(`localhost:3000`)에서는 정상 작동

#### 원인 분석
1. **서버 바인딩 문제**: 서버가 `localhost`에만 바인딩되어 외부 접속 불가
2. **프론트엔드 API URL 문제**: `script.js`에서 `localhost:3000`을 하드코딩

#### 해결 방법

**server.js 수정:**
```javascript
// 수정 전
app.listen(PORT, () => {
  console.log(`🚀 서버가 http://localhost:${PORT} 에서 실행 중입니다.`);
});

// 수정 후
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 서버가 http://0.0.0.0:${PORT} 에서 실행 중입니다.`);
  console.log(`🌐 외부 접속: http://your-ec2-public-ip:${PORT}`);
});
```

**script.js 수정:**
```javascript
// 수정 전
const API_BASE_URL = 'http://localhost:3000/api';

// 수정 후
const API_BASE_URL = `${window.location.protocol}//${window.location.hostname}:${window.location.port || '3000'}/api`;
```

### 3. EC2 배포 과정

#### 초기 문제
- `npm install` 실행 시 `package.json`을 찾을 수 없음
- PM2 프로세스가 "errored" 상태
- 포트 3000 충돌 (EADDRINUSE)

#### 해결 과정
1. 프로젝트 디렉토리 확인 및 이동
2. PM2 완전 정리 및 재시작
3. 포트 충돌 해결
4. 서버 코드 수정 및 재시작

#### 최종 상태
- PM2 상태: online
- 포트 바인딩: `0.0.0.0:3000`
- 데이터베이스 연결: 성공
- EC2 보안 그룹: 포트 3000 인바운드 규칙 추가

### 4. EC2 보안 그룹 설정

#### 설정 내용
- **유형**: 커스텀 TCP
- **포트 범위**: 3000
- **소스**: `0.0.0.0/0` (IPv4), `::/0` (IPv6)
- **설명**: "Todo App Port 3000"

### 5. Git 업데이트

#### 커밋 내역
1. **외부 접속 문제 해결 및 문서 정리**
   - script.js: API_BASE_URL을 현재 호스트로 동적 설정
   - server.js: 0.0.0.0에 바인딩하여 외부 접속 허용
   - TROUBLESHOOTING.md: 외부 접속 문제 해결 방법 추가
   - 문서 정리: 중복 문서 통합 및 링크 업데이트

2. **fix-db-auth.sh 파일 이름 변경**
   - `fix-db-auth.sh` → `fix-db-auth.sh.backup`

## 🔧 해결된 문제들

### 1. package.json을 찾을 수 없음 (ENOENT)
- **원인**: 프로젝트 디렉토리로 이동하지 않고 명령 실행
- **해결**: `cd ~/todo_AWS` 후 명령 실행

### 2. PM2 프로세스가 errored 상태
- **원인**: 포트 충돌 또는 데이터베이스 연결 실패
- **해결**: PM2 완전 정리 후 재시작, 포트 확인

### 3. 포트 3000 충돌 (EADDRINUSE)
- **원인**: 이전 프로세스가 포트를 점유
- **해결**: `pm2 delete all`, `pm2 kill`, `sudo pkill -f node` 후 재시작

### 4. 외부 접속 불가
- **원인**: 
  - 서버가 localhost에만 바인딩
  - 프론트엔드가 localhost를 하드코딩
- **해결**: 
  - server.js를 0.0.0.0에 바인딩
  - script.js에서 동적 호스트 사용

## 📝 주요 명령어

### PM2 관리
```bash
# 상태 확인
pm2 status

# 로그 확인
pm2 logs todo-app --lines 20

# 재시작
pm2 restart todo-app --update-env

# 완전 재시작
pm2 delete all
pm2 kill
pm2 start server.js --name todo-app --update-env
pm2 save
```

### 포트 확인
```bash
# 포트 사용 확인
sudo ss -tlnp | grep :3000

# 포트 해제 확인
sudo lsof -i :3000
```

### Git 업데이트
```bash
# 최신 코드 가져오기
git pull origin main

# 충돌 해결
git stash
git pull origin main
```

## ✅ 최종 확인 사항

- [x] 서버가 `0.0.0.0:3000`에 바인딩됨
- [x] 포트가 `*:3000`에 리스닝 중
- [x] 데이터베이스 연결 성공
- [x] PM2 상태: online
- [x] EC2 보안 그룹 설정 완료
- [x] 프론트엔드 API URL 동적 설정
- [x] Git 업데이트 완료

## 🌐 접속 정보

- **EC2 퍼블릭 IP**: `52.79.226.150`
- **접속 URL**: `http://52.79.226.150:3000`
- **API 엔드포인트**: `http://52.79.226.150:3000/api/todos`

## 📚 참고 문서

- `README.md` - 프로젝트 소개 및 빠른 시작
- `AWS_DEPLOY.md` - AWS 배포 상세 가이드
- `DEPLOY_QUICK.md` - 빠른 배포 가이드
- `TROUBLESHOOTING.md` - 문제 해결 가이드

## 💡 배운 점

1. **서버 바인딩**: 외부 접속을 위해서는 `0.0.0.0`에 바인딩해야 함
2. **프론트엔드 URL**: 하드코딩 대신 동적 호스트 사용
3. **EC2 보안 그룹**: 인바운드 규칙 설정이 필수
4. **PM2 관리**: 완전 정리 후 재시작이 중요
5. **포트 충돌**: 이전 프로세스 확인 및 정리 필요

---

**작성일**: 2025년 11월 18일  
**작성자**: 배포 세션 로그


