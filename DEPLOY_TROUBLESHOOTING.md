# 배포 문제 해결 가이드

## 포트 3000 충돌 오류 (EADDRINUSE)

### 증상
```
Error: listen EADDRINUSE: address already in use :::3000
```

### 원인
- PM2 프로세스가 이미 실행 중
- 다른 프로세스가 포트 3000을 사용 중
- 이전 배포에서 프로세스가 제대로 종료되지 않음

### 해결 방법

#### 방법 1: 자동 해결 스크립트 사용 (권장)

```bash
# 포트 충돌 해결 스크립트 실행
chmod +x fix-port-error.sh
./fix-port-error.sh

# 그 후 애플리케이션 재시작
pm2 start server.js --name todo
```

#### 방법 2: 수동 해결

**1단계: PM2 프로세스 확인 및 중지**
```bash
# PM2 프로세스 목록 확인
pm2 list

# todo 프로세스 중지
pm2 stop todo

# todo 프로세스 삭제
pm2 delete todo

# 또는 모든 PM2 프로세스 중지
pm2 stop all
pm2 delete all
```

**2단계: 포트 3000 사용 프로세스 확인 및 종료**
```bash
# 방법 A: lsof 사용 (Ubuntu)
sudo lsof -i :3000
# PID를 확인한 후
sudo kill -9 <PID>

# 방법 B: ss 사용
sudo ss -ltnp | grep :3000
# PID를 확인한 후
sudo kill -9 <PID>

# 방법 C: netstat 사용
sudo netstat -tlnp | grep :3000
# PID를 확인한 후
sudo kill -9 <PID>
```

**3단계: 포트 해제 확인**
```bash
# 포트가 해제되었는지 확인
sudo lsof -i :3000
# 아무것도 출력되지 않으면 포트가 해제됨

# 또는
sudo ss -ltnp | grep :3000
```

**4단계: 애플리케이션 재시작**
```bash
pm2 start server.js --name todo
pm2 save
```

#### 방법 3: 배포 스크립트 사용 (자동 해결)

업데이트된 배포 스크립트는 포트 충돌을 자동으로 해결합니다:

```bash
./deploy.sh
```

## 기타 일반적인 오류

### PM2 프로세스가 시작되지 않음

**해결:**
```bash
# PM2 프로세스 목록 확인
pm2 list

# 로그 확인
pm2 logs todo

# 프로세스 재시작
pm2 restart todo

# 또는 삭제 후 재시작
pm2 delete todo
pm2 start server.js --name todo
```

### 데이터베이스 연결 실패

**해결:**
```bash
# .env 파일 확인
cat .env

# 환경변수가 올바르게 로드되는지 확인
node -e "require('dotenv').config(); console.log(process.env.DB_HOST);"

# 데이터베이스 연결 테스트
mysql -h your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com \
      -P 3307 \
      -u root \
      -p \
      -e "USE todo; SELECT COUNT(*) FROM todos;"
```

### npm install 오류

**해결:**
```bash
# node_modules 삭제 후 재설치
rm -rf node_modules
npm install --production

# 또는 npm 캐시 클리어
npm cache clean --force
rm -rf node_modules package-lock.json
npm install --production
```

### Git 업데이트 실패

**해결:**
```bash
# Git 상태 확인
git status

# 변경사항 저장 (선택사항)
git stash

# 최신 코드 가져오기
git pull origin main

# 충돌 해결 후
npm install --production
pm2 restart todo
```

### PM2 자동 시작이 작동하지 않음

**해결:**
```bash
# PM2 자동 시작 설정
pm2 startup

# 출력된 명령어 실행 (sudo 포함)
# 예: sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu

# 현재 프로세스 저장
pm2 save
```

## 빠른 진단 명령어

```bash
# 1. PM2 상태 확인
pm2 status

# 2. 포트 사용 확인
sudo lsof -i :3000

# 3. 로그 확인
pm2 logs todo --lines 50

# 4. 시스템 리소스 확인
free -h
df -h

# 5. Node.js 버전 확인
node --version
npm --version

# 6. 프로세스 확인
ps aux | grep node

# 7. 네트워크 연결 확인
netstat -tlnp | grep 3000
```

## 예방 방법

1. **배포 전 항상 이전 프로세스 정리**
   ```bash
   pm2 delete todo 2>/dev/null || true
   ```

2. **배포 스크립트 사용**
   - `deploy.sh` 또는 `deploy-first-time.sh`를 사용하면 자동으로 처리됩니다.

3. **포트 확인 습관화**
   ```bash
   # 배포 전 포트 확인
   sudo lsof -i :3000 || echo "포트 3000은 사용 가능합니다"
   ```

## 추가 리소스

- PM2 문서: https://pm2.keymetrics.io/docs/
- Node.js 포트 충돌: https://nodejs.org/api/net.html#net_server_listen

