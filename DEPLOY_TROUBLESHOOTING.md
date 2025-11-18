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

## 데이터베이스 인증 오류 (ER_ACCESS_DENIED_ERROR)

### 증상
```
Access denied for user 'root'@'172.31.44.73' (using password: YES)
errno: 1045
code: 'ER_ACCESS_DENIED_ERROR'
```

### 원인
- 사용자명 또는 비밀번호가 잘못됨
- RDS 보안 그룹에서 EC2 인스턴스의 IP/보안 그룹이 허용되지 않음
- .env 파일이 올바른 폴더에 없거나 PM2가 환경변수를 로드하지 못함

### 해결 방법

#### 방법 1: 자동 해결 스크립트 사용 (권장)

```bash
# 스크립트 다운로드 및 실행
cd ~/todo_AWS
git pull origin main
chmod +x fix-db-auth.sh
./fix-db-auth.sh
```

#### 방법 2: 수동 해결 (단계별)

**1단계: .env 파일 확인 및 복사**
```bash
# 원본 폴더의 .env 확인
cat ~/todo_AWS/.env | grep -v PASSWORD

# todo-app 폴더로 복사
cp ~/todo_AWS/.env ~/todo-app/.env
chmod 600 ~/todo-app/.env

# 복사된 파일 확인
cat ~/todo-app/.env | grep -v PASSWORD
```

**2단계: .env 파일 편집 (비밀번호 확인)**
```bash
cd ~/todo-app
nano .env
```

다음 항목을 확인하세요:
- `DB_HOST`: RDS 엔드포인트 (예: `todo.c5aac4i6et2q.ap-northeast-2.rds.amazonaws.com`)
- `DB_PORT`: 3307
- `DB_USER`: root (또는 RDS 마스터 사용자명)
- `DB_PASSWORD`: RDS 마스터 비밀번호 (정확히 확인!)
- `DB_NAME`: todo

**3단계: 환경변수 로드 확인**
```bash
cd ~/todo-app
node -e "require('dotenv').config(); console.log('DB_HOST:', process.env.DB_HOST); console.log('DB_USER:', process.env.DB_USER); console.log('DB_NAME:', process.env.DB_NAME);"
```

**4단계: 데이터베이스 연결 직접 테스트**
```bash
# MariaDB/MySQL 클라이언트 설치 (없는 경우)
sudo apt-get install -y mariadb-client

# 직접 연결 테스트
mysql -h $(grep DB_HOST ~/todo-app/.env | cut -d'=' -f2) \
      -P $(grep DB_PORT ~/todo-app/.env | cut -d'=' -f2) \
      -u $(grep DB_USER ~/todo-app/.env | cut -d'=' -f2) \
      -p$(grep DB_PASSWORD ~/todo-app/.env | cut -d'=' -f2) \
      -e "SELECT USER(), DATABASE(), @@hostname;"
```

**5단계: PM2 완전 재시작**
```bash
# PM2 프로세스 완전 삭제
pm2 delete todo-app

# todo-app 폴더로 이동
cd ~/todo-app

# .env 파일 확인
ls -la .env

# PM2로 재시작 (환경변수 명시적 로드)
pm2 start server.js --name todo-app --update-env
pm2 save

# 잠시 대기
sleep 5

# 로그 확인
pm2 logs todo-app --lines 30
```

**6단계: RDS 보안 그룹 확인**

1. AWS 콘솔 → RDS → 데이터베이스 → 인스턴스 선택
2. **연결 및 보안** 탭 → **보안** 섹션의 **보안 그룹** 클릭
3. **인바운드 규칙 편집**:
   - Type: MySQL/Aurora
   - Port: 3307
   - Source: EC2 인스턴스의 보안 그룹 ID (권장) 또는 `172.31.44.73/32`

**7단계: RDS 퍼블릭 액세스 확인**

1. RDS 콘솔 → 인스턴스 선택
2. **연결 및 보안** 탭
3. **퍼블릭 액세스 가능**이 **예**인지 확인

**8단계: RDS 비밀번호 재확인**

RDS 콘솔에서:
1. 데이터베이스 → 인스턴스 선택
2. **구성** 탭
3. **마스터 사용자 이름** 확인
4. 마스터 비밀번호가 `.env`의 `DB_PASSWORD`와 일치하는지 확인

비밀번호를 모르거나 변경이 필요한 경우:
- RDS 콘솔에서 비밀번호 수정 가능 (인스턴스 재부팅 필요)
- 또는 AWS CLI 사용:
```bash
aws rds modify-db-instance \
  --db-instance-identifier todo \
  --master-user-password 새비밀번호 \
  --apply-immediately
```

### 데이터베이스 연결 실패 (일반)

**해결:**
```bash
# .env 파일 확인
cat ~/todo-app/.env

# 환경변수가 올바르게 로드되는지 확인
cd ~/todo-app
node -e "require('dotenv').config(); console.log('DB_HOST:', process.env.DB_HOST);"

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

