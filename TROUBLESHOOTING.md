# 문제 해결 가이드

이 문서는 Todo 애플리케이션의 일반적인 문제와 해결 방법을 다룹니다.

## 📋 목차

1. [로컬 개발 환경 문제](#로컬-개발-환경-문제)
2. [배포 문제](#배포-문제)
3. [RDS 연결 문제](#rds-연결-문제)
4. [빠른 진단 명령어](#빠른-진단-명령어)

---

## 로컬 개발 환경 문제

### 할일 추가 실패 오류

#### 증상
할일 추가가 실패하거나 데이터베이스 오류가 발생

#### 해결 방법

**1. 데이터베이스가 생성되었는지 확인**

```sql
-- MariaDB 클라이언트에서 실행
SHOW DATABASES;
USE todo;
SHOW TABLES;
DESCRIBE todos;
```

데이터베이스나 테이블이 없다면 `database.sql` 파일을 실행:

```bash
mysql -u root -p1234 -P 3307 < database.sql
```

**2. MariaDB 서버가 실행 중인지 확인**

Windows:
```powershell
Get-Service | Where-Object {$_.Name -like "*mariadb*" -or $_.Name -like "*mysql*"}
```

**3. 서버가 실행 중인지 확인**

```bash
npm start
# 또는
npm run dev
```

서버 콘솔에서 다음 메시지 확인:
- `✅ MariaDB 연결 성공`
- `🚀 서버가 http://localhost:3000 에서 실행 중입니다.`

**4. 연결 정보 확인**

`server.js` 파일의 데이터베이스 연결 설정 확인:

```javascript
const pool = mariadb.createPool({
  host: 'localhost',
  port: 3307,
  user: 'root',
  password: '1234',
  database: 'todo',
  connectionLimit: 5
});
```

또는 `.env` 파일 사용 시 환경변수 확인

**5. 브라우저 콘솔 확인**

브라우저 개발자 도구(F12)의 콘솔 탭에서 오류 메시지 확인

**6. 서버 로그 확인**

터미널에서 오류 메시지 확인:
- `ER_BAD_DB_ERROR`: 데이터베이스가 없음
- `ER_NO_SUCH_TABLE`: 테이블이 없음
- `ECONNREFUSED`: MariaDB 서버에 연결할 수 없음

### 일반적인 오류 메시지

| 오류 메시지 | 해결 방법 |
|------------|----------|
| "데이터베이스가 없습니다" | `database.sql` 파일 실행 |
| "데이터베이스 테이블이 없습니다" | `database.sql` 파일 실행 |
| "데이터베이스 연결에 실패했습니다" | MariaDB 서버 실행 확인 |
| "서버에 연결할 수 없습니다" | `npm start` 실행 확인 |

---

## 배포 문제

### package.json을 찾을 수 없음 (ENOENT)

#### 증상
```
npm ERR! code ENOENT
npm ERR! path /home/ubuntu/package.json
npm ERR! errno -2
npm ERR! enoent ENOENT: no such file or directory, open '/home/ubuntu/package.json'
```

#### 원인
프로젝트 디렉토리로 이동하지 않고 홈 디렉토리(`~`)에서 명령을 실행함

#### 해결 방법

**1. 프로젝트 디렉토리 찾기**

```bash
# 프로젝트 디렉토리 확인
ls -la ~/ | grep todo

# 일반적인 프로젝트 디렉토리:
# - ~/todo-app (배포용)
# - ~/todo_AWS (원본)
```

**2. 프로젝트 디렉토리로 이동**

```bash
# 배포 디렉토리로 이동
cd ~/todo-app

# 또는 원본 디렉토리로 이동
cd ~/todo_AWS

# package.json 파일 확인
ls -la package.json
```

**3. 의존성 설치**

```bash
# 프로젝트 디렉토리에서 실행
cd ~/todo-app
npm install --omit=dev
# 또는
npm install --production
```

**4. 배포 스크립트 사용 (권장)**

배포 스크립트는 자동으로 올바른 디렉토리에서 실행합니다:

```bash
# 어느 디렉토리에서든 실행 가능
cd ~/todo_AWS
./deploy.sh
```

### 포트 3000 충돌 오류 (EADDRINUSE)

#### 증상
```
Error: listen EADDRINUSE: address already in use :::3000
```

#### 원인
- PM2 프로세스가 이미 실행 중
- 다른 프로세스가 포트 3000을 사용 중
- 이전 배포에서 프로세스가 제대로 종료되지 않음

#### 해결 방법

**방법 1: 자동 해결 스크립트 사용 (권장)**

```bash
chmod +x fix-port-error.sh
./fix-port-error.sh
pm2 start server.js --name todo-app
```

**방법 2: 수동 해결**

```bash
# 1. PM2 프로세스 확인 및 중지
pm2 list
pm2 stop todo-app
pm2 delete todo-app

# 2. 포트 3000 사용 프로세스 확인 및 종료
sudo lsof -i :3000
# 또는
sudo ss -ltnp | grep :3000
# PID 확인 후
sudo kill -9 <PID>

# 3. 애플리케이션 재시작
pm2 start server.js --name todo-app
pm2 save
```

**방법 3: 배포 스크립트 사용**

업데이트된 배포 스크립트는 포트 충돌을 자동으로 해결합니다:

```bash
./deploy.sh
```

### PM2 프로세스가 errored 상태

#### 증상
```
│ 0  │ todo-app  │ fork  │ 15  │ errored  │ 0%  │ 0b  │
```
- 상태가 "errored"로 표시됨
- 재시작 횟수(↺)가 계속 증가함
- 메모리 사용량이 0b

#### 원인
애플리케이션이 시작되다가 오류로 인해 계속 재시작되고 있음

#### 해결 방법

**1. 로그 확인 (가장 중요!)**

```bash
# 최근 로그 확인
pm2 logs todo-app --lines 50

# 실시간 로그 확인
pm2 logs todo-app

# 에러 로그만 확인
pm2 logs todo-app --err --lines 50
```

**2. 일반적인 오류 원인 및 해결**

**데이터베이스 연결 실패:**
```bash
# .env 파일 확인
cat .env

# .env 파일이 있는지 확인
ls -la .env

# 환경변수 로드 테스트
node -e "require('dotenv').config(); console.log('DB_HOST:', process.env.DB_HOST);"
```

**포트 충돌:**
```bash
# 포트 3000 사용 확인
sudo lsof -i :3000
# 또는
sudo ss -ltnp | grep :3000
```

**의존성 문제:**
```bash
# node_modules 확인
ls -la node_modules

# 의존성 재설치
rm -rf node_modules package-lock.json
npm install --omit=dev
```

**3. 프로세스 재시작**

```bash
# 1. 프로세스 삭제
pm2 delete todo-app

# 2. 프로젝트 디렉토리 확인 (중요!)
pwd
# ~/todo-app 또는 ~/todo_AWS 여야 함

# 3. .env 파일 확인
ls -la .env

# 4. 직접 실행하여 오류 확인
node server.js
# 오류 메시지를 확인하고 해결

# 5. 오류 해결 후 PM2로 재시작
pm2 start server.js --name todo-app --update-env
pm2 save
```

**4. 디렉토리 문제 확인**

```bash
# 현재 디렉토리 확인
pwd

# 올바른 디렉토리로 이동
cd ~/todo-app
# 또는
cd ~/todo_AWS

# server.js 파일 확인
ls -la server.js

# PM2 재시작
pm2 delete todo-app
pm2 start server.js --name todo-app --update-env
```

### PM2 프로세스가 시작되지 않음

**해결:**
```bash
# PM2 프로세스 목록 확인
pm2 list

# 로그 확인
pm2 logs todo-app

# 프로세스 재시작
pm2 restart todo-app

# 또는 삭제 후 재시작
pm2 delete todo-app
pm2 start server.js --name todo-app
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
pm2 restart todo-app
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

### .env 파일 수정 후

```bash
# PM2 재시작 (환경변수 반영)
pm2 restart todo-app --update-env
```

---

## RDS 연결 문제

### 오류 메시지
```
Access denied for user 'root'@'172.31.44.73' (using password: YES)
errno: 1045
code: 'ER_ACCESS_DENIED_ERROR'
```

### 발생 원인 (우선순위별)

#### 1. 비밀번호 불일치 (가장 흔함) ⚠️

**원인**: RDS 마스터 비밀번호와 `.env` 파일의 `DB_PASSWORD`가 일치하지 않음

**확인 방법:**
```bash
# .env 파일 확인
cat ~/todo-app/.env | grep DB_PASSWORD

# RDS 콘솔에서 마스터 비밀번호 확인
# AWS 콘솔 → RDS → 데이터베이스 → 인스턴스 → 구성 탭
```

#### 2. 사용자명 불일치

**원인**: RDS 마스터 사용자명과 `.env` 파일의 `DB_USER`가 일치하지 않음

**확인 방법:**
```bash
cat ~/todo-app/.env | grep DB_USER
```

#### 3. RDS 보안 그룹 설정 문제

**원인**: RDS 보안 그룹에서 EC2 인스턴스의 IP/보안 그룹을 허용하지 않음

**확인 방법:**
1. RDS 콘솔 → 데이터베이스 → 인스턴스 선택
2. 연결 및 보안 탭 → 보안 그룹 클릭
3. 인바운드 규칙 확인:
   - Type: MySQL/Aurora
   - Port: 3307
   - Source: EC2 보안 그룹 ID 또는 EC2 프라이빗 IP

#### 4. RDS 퍼블릭 액세스 비활성화

**확인 방법:**
- RDS 콘솔 → 인스턴스 → 연결 및 보안 탭
- "퍼블릭 액세스 가능" 확인

#### 5. .env 파일이 올바른 위치에 없음

**확인 방법:**
```bash
# .env 파일 위치 확인
ls -la ~/todo-app/.env
ls -la ~/todo_AWS/.env

# PM2 작업 디렉토리 확인
pm2 info todo-app | grep "exec cwd"
```

#### 6. PM2가 환경변수를 캐시

**해결**: PM2 완전 삭제 후 재시작

### 단계별 해결 방법

#### Step 1: .env 파일 확인 및 수정

```bash
# 1. .env 파일 위치 확인
cd ~/todo-app
ls -la .env

# 2. .env 파일 없으면 복사
if [ ! -f .env ]; then
    cp ~/todo_AWS/.env .env
    chmod 600 .env
fi

# 3. .env 파일 내용 확인 (비밀번호 제외)
cat .env | grep -v PASSWORD

# 4. .env 파일 편집
nano .env
```

**.env 파일 필수 확인 사항:**
```bash
PORT=3000
DB_HOST=todo.c5aac4i6et2q.ap-northeast-2.rds.amazonaws.com  # 실제 RDS 엔드포인트
DB_PORT=3307
DB_USER=root  # RDS 마스터 사용자명 (정확히 확인!)
DB_PASSWORD=qwer1257  # RDS 마스터 비밀번호 (정확히 확인!)
DB_NAME=todo
DB_CONNECTION_LIMIT=5
```

#### Step 2: RDS 콘솔에서 정보 확인

1. **RDS 인스턴스 선택**
   - AWS 콘솔 → RDS → 데이터베이스 → 인스턴스 선택

2. **연결 정보 확인**
   - **엔드포인트**: 연결 및 보안 탭 → 엔드포인트 복사
   - **포트**: 연결 및 보안 탭 → 포트 (보통 3306, 커스텀 포트는 3307)
   - **마스터 사용자 이름**: 구성 탭 → 마스터 사용자 이름
   - **마스터 비밀번호**: 구성 탭 → 마스터 비밀번호 (표시되지 않음, 알려진 비밀번호 사용)

3. **.env 파일과 일치 확인**
```bash
cat ~/todo-app/.env | grep DB_HOST
cat ~/todo-app/.env | grep DB_USER
cat ~/todo-app/.env | grep DB_PORT
```

#### Step 3: RDS 보안 그룹 설정 확인 및 수정

1. **RDS 보안 그룹 확인**
   - RDS 콘솔 → 데이터베이스 → 인스턴스 선택
   - 연결 및 보안 탭 → 보안 섹션 → 보안 그룹 클릭

2. **인바운드 규칙 확인 및 추가**
   - **인바운드 규칙** 탭 → **인바운드 규칙 편집**
   - **규칙 추가:**
     - **유형**: MySQL/Aurora
     - **포트**: 3307
     - **소스**: 
       - **방법 1 (권장)**: EC2 인스턴스의 보안 그룹 ID 선택
       - **방법 2**: EC2 프라이빗 IP 허용 (예: `172.31.44.73/32`)
     - **설명**: "EC2 todo-app access"
   - **저장** 클릭

#### Step 4: RDS 퍼블릭 액세스 확인

- RDS 콘솔 → 인스턴스 → 연결 및 보안 탭
- **퍼블릭 액세스 가능**: "예" 여야 함

**만약 "아니오"인 경우:**
- EC2와 RDS가 같은 VPC에 있어야 함
- 또는 RDS 인스턴스를 수정하여 퍼블릭 액세스 활성화
- ⚠️ 주의: 수정 시 RDS 인스턴스 재부팅이 필요할 수 있음

#### Step 5: 직접 연결 테스트

```bash
# MariaDB 클라이언트 설치 (없는 경우)
sudo apt-get update
sudo apt-get install -y mariadb-client

# .env 파일에서 정보 읽기
cd ~/todo-app
source .env 2>/dev/null || true

# 직접 연결 테스트
mysql -h "${DB_HOST}" \
      -P "${DB_PORT:-3307}" \
      -u "${DB_USER}" \
      -p"${DB_PASSWORD}" \
      -e "SELECT USER(), DATABASE(), @@hostname, @@port;"
```

**성공 시 출력 예시:**
```
+----------------+----------+-------------------------------+-------+
| USER()         | DATABASE | @@hostname                    | @@port |
+----------------+----------+-------------------------------+-------+
| root@172.31... | todo     | ip-10-0-1-23.ec2.internal     |  3307 |
+----------------+----------+-------------------------------+-------+
```

**실패 시 확인:**
- 비밀번호 오류: `Access denied for user...`
- 네트워크 오류: `ERROR 2003 (HY000): Can't connect to MySQL server...`

#### Step 6: 환경변수 로드 확인

```bash
cd ~/todo-app

# Node.js로 환경변수 로드 확인
node -e "
require('dotenv').config();
console.log('DB_HOST:', process.env.DB_HOST || 'NOT SET');
console.log('DB_PORT:', process.env.DB_PORT || 'NOT SET');
console.log('DB_USER:', process.env.DB_USER || 'NOT SET');
console.log('DB_NAME:', process.env.DB_NAME || 'NOT SET');
console.log('DB_PASSWORD:', process.env.DB_PASSWORD ? '[SET]' : 'NOT SET');
"
```

#### Step 7: PM2 완전 재시작

```bash
# 1. PM2 프로세스 완전 삭제
pm2 delete todo-app

# 2. todo-app 폴더로 이동 (중요!)
cd ~/todo-app

# 3. .env 파일 존재 확인
ls -la .env
cat .env | grep -v PASSWORD

# 4. PM2로 시작 (.env 파일이 있는 디렉토리에서 실행)
pm2 start server.js --name todo-app --update-env

# 5. PM2 저장
pm2 save

# 6. 잠시 대기
sleep 5

# 7. 로그 확인
pm2 logs todo-app --lines 50
```

#### Step 8: 최종 확인

```bash
# API 테스트
curl http://localhost:3000/api/todos

# 성공 시 JSON 응답 또는 빈 배열 []
# 실패 시 연결 오류 메시지
```

### 자동 해결 스크립트 사용

위의 모든 단계를 자동으로 수행하는 스크립트:

```bash
# 1. 최신 코드 가져오기
cd ~/todo_AWS
git pull origin main

# 2. 자동 해결 스크립트 실행
chmod +x fix-db-auth.sh
./fix-db-auth.sh
```

### 체크리스트

다음을 순서대로 확인하세요:

- [ ] `.env` 파일이 `~/todo-app/` 폴더에 있음
- [ ] `.env` 파일의 `DB_HOST`가 RDS 엔드포인트와 일치
- [ ] `.env` 파일의 `DB_USER`가 RDS 마스터 사용자명과 일치
- [ ] `.env` 파일의 `DB_PASSWORD`가 RDS 마스터 비밀번호와 일치
- [ ] `.env` 파일의 `DB_PORT`가 3307 (또는 RDS 포트와 일치)
- [ ] RDS 보안 그룹에서 EC2 IP/보안 그룹 허용
- [ ] RDS 퍼블릭 액세스 활성화됨
- [ ] `mysql` 명령어로 직접 연결 성공
- [ ] Node.js로 환경변수 로드 확인 완료
- [ ] PM2가 `~/todo-app/` 디렉토리에서 실행됨
- [ ] PM2 재시작 후 로그 확인

---

### 외부에서 접속할 수 없음

#### 증상
- 로컬(`localhost:3000`)에서는 접속 가능
- 외부 IP(`52.79.226.150:3000`)에서는 접속 불가
- 브라우저에서 "서버에 연결할 수 없습니다" 오류

#### 원인
- EC2 보안 그룹에서 포트 3000 인바운드 규칙이 없음
- 방화벽(UFW)에서 포트 3000이 차단됨

#### 해결 방법

**1. EC2 보안 그룹 설정 (가장 중요!)**

1. **AWS 콘솔 접속**
   - AWS 콘솔 → EC2 → 인스턴스 선택

2. **보안 그룹 확인**
   - 인스턴스 선택 → **보안** 탭 → **보안 그룹** 클릭

3. **인바운드 규칙 편집**
   - **인바운드 규칙** 탭 → **인바운드 규칙 편집** 클릭
   - **규칙 추가** 클릭
   - 다음 설정:
     - **유형**: 커스텀 TCP
     - **포트 범위**: 3000
     - **소스**: 
       - 테스트용: `0.0.0.0/0` (모든 IP 허용)
       - 프로덕션: 특정 IP만 허용
     - **설명**: "Todo App Port 3000"
   - **규칙 저장** 클릭

4. **확인**
   - 인바운드 규칙에 포트 3000이 추가되었는지 확인

**2. 방화벽(UFW) 확인 (Ubuntu)**

```bash
# UFW 상태 확인
sudo ufw status

# 포트 3000 허용 (필요한 경우)
sudo ufw allow 3000/tcp

# UFW 활성화 (비활성화된 경우)
sudo ufw enable

# 상태 재확인
sudo ufw status
```

**3. 서버 바인딩 확인**

서버가 모든 인터페이스에 바인딩되도록 확인:

```bash
# server.js 파일 확인
grep "app.listen" server.js

# 0.0.0.0에 바인딩되도록 수정 (필요한 경우)
# app.listen(PORT, '0.0.0.0', () => {
```

**4. 접속 테스트**

```bash
# EC2에서 로컬 테스트
curl http://localhost:3000/api/todos

# 외부에서 테스트 (다른 컴퓨터에서)
curl http://52.79.226.150:3000/api/todos
```

**5. 포트 확인**

```bash
# 포트가 리스닝 중인지 확인
sudo ss -tlnp | grep :3000

# 모든 인터페이스에 바인딩되었는지 확인
# 0.0.0.0:3000 또는 *:3000 이어야 함
```

---

## 빠른 진단 명령어

```bash
# 1. PM2 상태 확인
pm2 status

# 2. 포트 사용 확인
sudo lsof -i :3000
# 또는
sudo ss -ltnp | grep :3000

# 3. 로그 확인
pm2 logs todo-app --lines 50

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

# 8. 환경변수 확인
cd ~/todo-app
cat .env | grep -v PASSWORD
```

---

## 예방 방법

1. **배포 전 항상 이전 프로세스 정리**
   ```bash
   pm2 delete todo-app 2>/dev/null || true
   ```

2. **배포 스크립트 사용**
   - `deploy.sh` 또는 `deploy-first-time.sh`를 사용하면 자동으로 처리됩니다.

3. **포트 확인 습관화**
   ```bash
   # 배포 전 포트 확인
   sudo lsof -i :3000 || echo "포트 3000은 사용 가능합니다"
   ```

4. **정기적인 백업**
   - 배포 전 중요한 변경사항은 백업하세요.

---

## 보안 권장사항

1. **비밀번호 보안**
   - `.env` 파일 권한: `chmod 600 .env`
   - Git에 커밋하지 않음 (`.gitignore`에 포함)
   - 정기적으로 비밀번호 변경

2. **보안 그룹 최소 권한 원칙**
   - 가능하면 보안 그룹 ID로 허용
   - 특정 IP만 허용
   - 모든 IP(0.0.0.0/0) 허용은 피하기

3. **RDS 접근 제한**
   - 필요시 퍼블릭 액세스 비활성화 (VPC 내부만 접근)
   - SSL/TLS 연결 사용 고려

---

## 추가 리소스

- [PM2 문서](https://pm2.keymetrics.io/docs/)
- [Node.js 포트 충돌](https://nodejs.org/api/net.html#net_server_listen)
- [AWS RDS 문서](https://docs.aws.amazon.com/rds/)
- [AWS 보안 그룹 가이드](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/working-with-security-groups.html)
