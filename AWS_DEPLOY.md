# AWS 배포 가이드

이 문서는 Todo 애플리케이션을 AWS에 배포하는 완전한 가이드입니다.

## 📋 목차
1. [빠른 시작 체크리스트](#빠른-시작-체크리스트)
2. [배포 전 준비사항](#배포-전-준비사항)
3. [AWS RDS 데이터베이스 설정](#aws-rds-데이터베이스-설정)
4. [배포 방법 선택](#배포-방법-선택)
   - [방법 1: AWS EC2 (추천 - 초보자용)](#방법-1-aws-ec2-추천---초보자용)
   - [방법 2: AWS Elastic Beanstalk](#방법-2-aws-elastic-beanstalk)
   - [방법 3: AWS App Runner](#방법-3-aws-app-runner)
   - [방법 4: Docker + ECS/EC2](#방법-4-docker--ecsec2)
5. [배포 후 확인](#배포-후-확인)
6. [트러블슈팅](#트러블슈팅)

---

## ✅ 빠른 시작 체크리스트

배포 전 확인사항:
- [ ] AWS 계정 생성 완료
- [ ] AWS CLI 설치 (선택사항, EC2 배포 시 유용)
- [ ] Git 리포지토리에 코드 푸시 완료
- [ ] 로컬에서 애플리케이션 정상 작동 확인
- [ ] `.env` 파일이 `.gitignore`에 포함되어 있는지 확인

## 배포 전 준비사항

### 1. 환경변수 설정

`env.example` 파일을 참고하여 `.env` 파일을 생성하세요:

```bash
# .env 파일 생성 (로컬 테스트용)
PORT=3000
DB_HOST=your-rds-endpoint.xxxxx.us-east-1.rds.amazonaws.com
DB_PORT=3307
DB_USER=root
DB_PASSWORD=qwer1257
DB_NAME=todo
DB_CONNECTION_LIMIT=5
```

⚠️ **주의**: `.env` 파일은 절대 Git에 커밋하지 마세요. (`.gitignore`에 이미 포함됨)

### 2. 데이터베이스 초기화

AWS RDS에 MariaDB 또는 MySQL을 생성한 후, `database.sql` 파일을 실행하여 테이블을 생성하세요.

### 3. 필요한 AWS 서비스

- **AWS 계정** (필수)
- **AWS RDS** (MariaDB 또는 MySQL)
- 배포 플랫폼 선택 (EC2, Elastic Beanstalk, App Runner 등)

---

## AWS RDS 데이터베이스 설정

### 1. RDS 인스턴스 생성

1. AWS 콘솔에서 **RDS** 서비스로 이동
2. **데이터베이스 생성** 클릭
3. 다음 설정:
   - **엔진 유형**: MariaDB 또는 MySQL
   - **템플릿**: 프로덕션 또는 개발/테스트
   - **DB 인스턴스 식별자**: `todo` (원하는 이름)
   - **마스터 사용자 이름**: `root` (또는 원하는 이름)
   - **마스터 암호**: 'qwer1257'(기억하세요)
   - **DB 인스턴스 클래스**: `db.t3.micro` (프리티어) 또는 필요한 크기
   - **스토리지**: 20GB (프리티어 최대)
   - **VPC**: 기본 VPC 사용 또는 새로 생성
   - **퍼블릭 액세스**: 예 (외부에서 접근 가능하도록)
   - **VPC 보안 그룹**: 새로 생성 또는 기존 사용
   - **데이터베이스 이름**: `todo`

### 2. 보안 그룹 설정

RDS 인스턴스 생성 후, 보안 그룹 설정이 중요합니다:

1. **RDS 인스턴스 선택** → **연결 및 보안** 탭 → **보안** 섹션의 **보안 그룹** 클릭

2. **인바운드 규칙 편집** 클릭

3. **규칙 추가** 클릭 후 다음 설정:
   - **유형**: MySQL/Aurora
   - **포트**: 3307 (사용자 정의 포트 사용 시)
   - **소스**: 
     - EC2 배포 시: EC2 인스턴스의 보안 그룹 선택 (권장)
     - 또는 특정 IP: `내 IP` 또는 EC2 인스턴스의 퍼블릭 IP
   - **설명**: "Todo App Access"

4. **규칙 저장** 클릭

⚠️ **중요**: 보안을 위해 최소한의 IP만 허용하세요.

### 3. RDS 엔드포인트 확인

RDS 인스턴스 생성 완료 후:

1. RDS 콘솔에서 인스턴스 선택
2. **연결 및 보안** 탭에서 **엔드포인트** 복사
   - 예: `todo-db.xxxxx.ap-northeast-2.rds.amazonaws.com`
3. **포트**: 3307

### 4. 데이터베이스 초기화

#### 방법 A: 로컬에서 실행 (MySQL/MariaDB 클라이언트 필요)

```bash
# Windows (PowerShell 또는 CMD)
mysql -h your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com `
      -P 3307 `
      -u root `
      -p `
      < database.sql

# 입력 후 비밀번호 입력: qwer1257
```

#### 방법 B: EC2 인스턴스에서 실행

EC2 인스턴스에 접속한 후:

```bash
# MariaDB 클라이언트 설치 (Ubuntu)
sudo apt-get update
sudo apt-get install -y mariadb-client

# 또는 MySQL 클라이언트 (Amazon Linux)
sudo dnf install -y mysql

# database.sql 파일 업로드 후 실행
mysql -h your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com \
      -P 3307 \
      -u root \
      -p \
      < database.sql
```

#### 방법 C: MySQL Workbench 또는 DBeaver 사용

1. 새 연결 생성
2. 호스트: RDS 엔드포인트
3. 포트: 3307
4. 사용자명: root
5. 비밀번호: qwer1257
6. 연결 후 `database.sql` 파일 실행

#### 데이터베이스 초기화 확인

```sql
USE todo;
SHOW TABLES;
-- todos 테이블이 보이면 성공
DESCRIBE todos;
-- 테이블 구조 확인
```

---

## 배포 방법 선택

### 방법 1: AWS EC2 (추천 - 초보자용)

**장점**: 완전한 제어권, 저렴한 비용, 초보자에게 가장 직관적

**예상 비용**: 프리티어 사용 시 월 $0 (12개월), 이후 t2.micro 기준 약 $10-15/월

#### 1. EC2 인스턴스 생성 (단계별)

1. **AWS 콘솔 로그인** → **EC2** 서비스 이동

2. **인스턴스 시작** 클릭

3. **이름 및 태그**:
   - 이름: `todo-app-server`

4. **애플리케이션 및 OS 이미지(AMI)**:
   - **Ubuntu 22.04 LTS** (권장) 또는 **Amazon Linux 2023**

5. **인스턴스 유형**:
   - `t2.micro` (프리티어 사용 가능)
   - 또는 `t3.micro`

6. **키 페어(로그인)**:
   - **새 키 페어 생성** 클릭
   - 이름: `todo-app-key`
   - 키 페어 유형: RSA
   - 파일 형식: `.pem` (Windows: `.ppk`도 가능)
   - **키 페어 생성** 클릭 → 파일 다운로드 후 안전하게 보관

7. **네트워크 설정**:
   - **편집** 클릭
   - **보안 그룹**: 새 보안 그룹 생성
   - 보안 그룹 이름: `todo-app-sg`
   - 규칙 추가:
     - **SSH** (포트 22): 내 IP
     - **HTTP** (포트 80): 어디서나 (0.0.0.0/0)
     - **HTTPS** (포트 443): 어디서나 (0.0.0.0/0)
     - **커스텀 TCP** (포트 3000): 어디서나 (테스트용, 나중에 제거 가능)

8. **스토리지 구성**:
   - 기본 8GB (프리티어)
   - 또는 필요시 20GB까지 무료

9. **고급 세부 정보**:
   - **IAM 인스턴스 프로파일**: 없음 (기본값)

10. **인스턴스 시작** 클릭 → **인스턴스 보기** 클릭

#### 2. EC2 인스턴스 접속

##### Windows (PuTTY 사용)

1. **PuTTY 다운로드 및 설치**: https://www.putty.org/

2. **PuTTYgen으로 키 변환**:
   - PuTTYgen 실행
   - **Load** → `.pem` 파일 선택 (파일 형식: All Files)
   - **Save private key** → `.ppk` 파일로 저장

3. **PuTTY 접속**:
   - Host Name: `ubuntu@your-ec2-public-ip` (Ubuntu의 경우)
   - 또는 `ec2-user@your-ec2-public-ip` (Amazon Linux의 경우)
   - Connection → SSH → Auth → Credentials
   - Private key file: `.ppk` 파일 선택
   - **Open** 클릭

##### Windows (PowerShell 사용 - Windows 10 이상)

```powershell
# 키 파일 권한 설정 (처음 한 번만)
icacls "C:\path\to\todo-app-key.pem" /inheritance:r
icacls "C:\path\to\todo-app-key.pem" /grant:r "%username%:R"

# SSH 접속
ssh -i "C:\path\to\todo-app-key.pem" ubuntu@your-ec2-public-ip
# 또는 Amazon Linux의 경우
ssh -i "C:\path\to\todo-app-key.pem" ec2-user@your-ec2-public-ip
```

##### macOS/Linux

```bash
# 키 파일 권한 설정 (처음 한 번만)
chmod 400 todo-app-key.pem

# SSH 접속
ssh -i todo-app-key.pem ubuntu@your-ec2-public-ip
# 또는 Amazon Linux의 경우
ssh -i todo-app-key.pem ec2-user@your-ec2-public-ip
```

⚠️ **EC2 퍼블릭 IP 확인**: EC2 콘솔 → 인스턴스 → **퍼블릭 IPv4 주소** 확인

#### 3. 시스템 업데이트 및 Node.js 설치

##### Ubuntu 22.04

```bash
# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# Node.js 18.x 설치
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 설치 확인
node --version  # v18.x.x 이상
npm --version   # 9.x.x 이상

# Git 설치 (필요한 경우)
sudo apt-get install -y git
```

##### Amazon Linux 2023

```bash
# 시스템 업데이트
sudo dnf update -y

# Node.js 18.x 설치
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# 설치 확인
node --version
npm --version

# Git 설치
sudo dnf install -y git
```

#### 4. 애플리케이션 배포

```bash
# 프로젝트 디렉토리 생성
mkdir -p ~/todo-app
cd ~/todo-app

# 방법 A: Git 리포지토리에서 클론
git clone https://github.com/your-username/your-repo.git .
# 또는
git clone https://github.com/your-username/your-repo.git ~/todo-app

# 방법 B: 파일 직접 업로드 (WinSCP, FileZilla 등 사용)
# ~/todo-app 디렉토리에 파일 업로드

# 프로젝트 디렉토리로 이동
cd ~/todo-app

# 의존성 설치
npm install --production
```

#### 5. 환경변수 설정

```bash
# .env 파일 생성
nano .env
```

다음 내용 입력 (RDS 엔드포인트는 실제 값으로 변경):

```bash
PORT=3000
DB_HOST=your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com
DB_PORT=3307
DB_USER=root
DB_PASSWORD=qwer1257
DB_NAME=todo
DB_CONNECTION_LIMIT=5
```

저장: `Ctrl + O` → `Enter` → `Ctrl + X`

#### 6. 애플리케이션 테스트

```bash
# 서버 시작
node server.js

# 다른 터미널 창에서 테스트
curl http://localhost:3000/api/todos

# 정상 작동 확인 후 Ctrl+C로 중지
```

#### 7. PM2로 프로세스 관리

```bash
# PM2 전역 설치
sudo npm install -g pm2

# 애플리케이션 시작
pm2 start server.js --name todo-app

# PM2 상태 확인
pm2 status

# 로그 확인
pm2 logs todo-app

# 자동 시작 설정 (서버 재부팅 시 자동 시작)
pm2 startup
# 출력된 명령어를 복사하여 실행 (sudo 포함)
pm2 save
```

#### 8. 방화벽 설정 (UFW - Ubuntu)

```bash
# UFW 설치 및 활성화
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp # HTTPS
sudo ufw allow 3000/tcp # Node.js (테스트용, 나중에 제거 가능)
sudo ufw enable
sudo ufw status
```

#### 9. Nginx 리버스 프록시 설정 (선택사항, 권장)

HTTP(80) 포트로 접속하도록 설정:

```bash
# Nginx 설치
sudo apt-get install -y nginx  # Ubuntu
# 또는
sudo dnf install -y nginx      # Amazon Linux

# Nginx 설정 파일 생성
sudo nano /etc/nginx/sites-available/todo-app
```

다음 내용 입력:

```nginx
server {
    listen 80;
    server_name your-domain.com your-ec2-public-ip;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# 설정 파일 심볼릭 링크 생성 (Ubuntu)
sudo ln -s /etc/nginx/sites-available/todo-app /etc/nginx/sites-enabled/

# 또는 Amazon Linux의 경우
sudo cp /etc/nginx/sites-available/todo-app /etc/nginx/conf.d/todo-app.conf

# 기본 설정 제거 (Ubuntu)
sudo rm /etc/nginx/sites-enabled/default

# Nginx 설정 테스트
sudo nginx -t

# Nginx 시작 및 자동 시작 설정
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

#### 10. 보안 그룹 최종 설정

Nginx 사용 시:

1. EC2 콘솔 → 보안 그룹 → `todo-app-sg` 선택
2. **인바운드 규칙 편집**
3. **포트 3000 규칙 삭제** (Nginx를 통해만 접속)
4. **포트 80, 443만 유지**

#### 11. 배포 완료 확인

```bash
# 브라우저에서 접속 테스트
# http://your-ec2-public-ip

# API 테스트
curl http://your-ec2-public-ip/api/todos

# PM2 모니터링
pm2 monit
```

---

### 방법 2: AWS Elastic Beanstalk

**장점**: 간단한 배포, 자동 스케일링, 로드 밸런서 포함

**예상 비용**: 프리티어 사용 시 약 $0-5/월, 이후 약 $20-30/월

#### 1. EB CLI 설치

```bash
# Python 및 pip 필요
pip install awsebcli

# 설치 확인
eb --version
```

#### 2. EB 초기화

프로젝트 디렉토리에서:

```bash
eb init
```

설정 선택:
- Region: 원하는 리전 (예: `ap-northeast-2` - 서울)
- Platform: `Node.js`
- Platform version: 최신 버전 (Node.js 18 또는 20)
- Application name: `todo-app`
- CodeCommit 사용 여부: `n` (GitHub 사용 권장)

#### 3. 환경변수 설정

`.ebextensions/environment.config` 파일이 이미 생성되어 있습니다. 

Elastic Beanstalk 콘솔에서 환경변수 설정 (권장):

1. Elastic Beanstalk 콘솔 → 애플리케이션 → 환경 선택
2. **구성** → **소프트웨어** → **편집**
3. **환경 속성** 섹션에서 다음 추가:
   - `PORT`: `3000`
   - `DB_HOST`: RDS 엔드포인트
   - `DB_PORT`: `3307`
   - `DB_USER`: `root`
   - `DB_PASSWORD`: `qwer1257` (또는 실제 비밀번호)
   - `DB_NAME`: `todo`
   - `DB_CONNECTION_LIMIT`: `5`

⚠️ **보안**: 프로덕션에서는 환경변수를 AWS Systems Manager Parameter Store에 저장하고 참조하세요.

#### 4. 환경 생성 및 배포

```bash
# 환경 생성 (처음 한 번만)
eb create todo-env

# 배포
eb deploy

# 또는 코드 커밋 후 자동 배포 설정
eb deploy --staged
```

#### 5. RDS 연결 설정

Elastic Beanstalk 환경에서 RDS 사용:

1. Elastic Beanstalk 콘솔 → 환경 선택
2. **구성** → **데이터베이스** → **편집**
3. **데이터베이스 추가** (새로 생성)
   - 또는 기존 RDS 연결: **데이터베이스 없음** 선택 후 환경변수에 RDS 엔드포인트 입력

#### 6. 환경 확인

```bash
# 환경 상태 확인
eb status

# 환경 URL 확인 및 브라우저에서 열기
eb open

# 로그 확인
eb logs

# SSH 접속
eb ssh
```

#### 7. 배포 확인

브라우저에서 Elastic Beanstalk 환경 URL로 접속하여 확인:
- 예: `http://todo-env.xxxxx.ap-northeast-2.elasticbeanstalk.com`

---

### 방법 3: AWS App Runner

**장점**: 서버리스, 자동 스케일링, 간단한 설정

#### 1. Dockerfile 사용

이 가이드의 [방법 4](#방법-4-docker--ecsec2)에서 제공하는 Dockerfile 사용

#### 2. App Runner 서비스 생성

1. AWS 콘솔에서 **App Runner** 서비스로 이동
2. **서비스 생성** 클릭
3. 소스 선택:
   - **소스**: GitHub 또는 ECR
   - **리포지토리**: 선택
   - **브랜치**: main 또는 master
4. 빌드 설정:
   - **빌드 명령**: `npm install`
   - **시작 명령**: `npm start`
5. 서비스 설정:
   - **포트**: 3000
   - **환경변수**: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME 설정

---

---

### 방법 4: Docker + ECS/EC2

**장점**: 일관된 환경, 컨테이너 오케스트레이션

#### 1. Dockerfile 생성

프로젝트 루트에 `Dockerfile` 파일이 있습니다.

#### 2. Docker 이미지 빌드 및 테스트

```bash
# 이미지 빌드
docker build -t todo-app .

# 로컬에서 테스트
docker run -p 3000:3000 --env-file .env todo-app
```

#### 3. ECR에 이미지 푸시

```bash
# ECR 리포지토리 생성 (AWS 콘솔에서)
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin your-account-id.dkr.ecr.ap-northeast-2.amazonaws.com

docker tag todo-app:latest your-account-id.dkr.ecr.ap-northeast-2.amazonaws.com/todo-app:latest
docker push your-account-id.dkr.ecr.ap-northeast-2.amazonaws.com/todo-app:latest
```

#### 4. ECS 태스크 정의 및 서비스 생성

AWS 콘솔 또는 CLI를 통해 ECS 클러스터, 태스크 정의, 서비스를 생성합니다.

---

## 배포 후 확인

### 1. 애플리케이션 접속 테스트

브라우저에서 접속:
- EC2: `http://your-ec2-public-ip` 또는 `http://your-ec2-public-ip:3000`
- Elastic Beanstalk: `http://your-env.region.elasticbeanstalk.com`
- App Runner: App Runner 서비스 URL

### 2. API 엔드포인트 테스트

```bash
# 할일 목록 조회
curl http://your-server-url/api/todos

# 할일 추가 테스트
curl -X POST http://your-server-url/api/todos \
  -H "Content-Type: application/json" \
  -d '{"text":"테스트 할일","details":"AWS 배포 테스트"}'

# 할일 목록 재조회
curl http://your-server-url/api/todos
```

### 3. 로그 확인

**EC2 + PM2:**
```bash
pm2 logs todo-app
# 또는 실시간 로그
pm2 logs todo-app --lines 50
```

**Elastic Beanstalk:**
```bash
eb logs
```

**EC2 + Nginx:**
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 4. 성능 모니터링

```bash
# PM2 모니터링
pm2 monit

# 시스템 리소스 확인
htop  # 또는 top
df -h  # 디스크 사용량
free -h  # 메모리 사용량
```

### 5. 데이터베이스 연결 확인

EC2에서 직접 테스트:
```bash
# MariaDB 클라이언트 설치
sudo apt-get install -y mariadb-client  # Ubuntu
# 또는
sudo dnf install -y mysql  # Amazon Linux

# 연결 테스트
mysql -h your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com \
      -P 3307 \
      -u root \
      -p \
      -e "USE todo; SELECT COUNT(*) FROM todos;"
```

---

## 보안 권장사항

### 1. 환경변수 보안

- 절대 `.env` 파일을 Git에 커밋하지 마세요
- 프로덕션에서는 AWS Secrets Manager 또는 Systems Manager Parameter Store 사용
- IAM 역할을 사용하여 RDS 접근 권한 관리

### 2. 데이터베이스 보안

- RDS는 퍼블릭 액세스를 비활성화하고 보안 그룹으로만 접근 허용
- SSL/TLS 연결 사용 (선택사항)
- 정기적인 백업 설정

### 3. HTTPS 설정

- AWS Certificate Manager (ACM)로 SSL 인증서 발급
- CloudFront 또는 ALB(Application Load Balancer)에서 HTTPS 설정

---

---

## 트러블슈팅

### 데이터베이스 연결 실패

**증상**: `ECONNREFUSED`, `ETIMEDOUT`, `ER_ACCESS_DENIED_ERROR`

**해결 방법**:

1. **RDS 보안 그룹 확인**:
   ```bash
   # EC2 인스턴스의 보안 그룹 ID 확인
   # EC2 콘솔 → 인스턴스 → 보안 탭
   
   # RDS 보안 그룹에서 EC2 보안 그룹 허용 확인
   # 또는 EC2 퍼블릭 IP 허용
   ```

2. **RDS 퍼블릭 액세스 확인**:
   - RDS 콘솔 → 인스턴스 → **연결 및 보안** 탭
   - **퍼블릭 액세스 가능**이 **예**인지 확인

3. **환경변수 값 확인**:
   ```bash
   # EC2에서 확인
   cat .env
   # 또는
   pm2 env 0  # PM2 환경변수 확인
   ```

4. **엔드포인트 및 포트 확인**:
   - RDS 콘솔에서 엔드포인트 정확히 복사
   - 포트: 3307
   - `.env` 파일의 `DB_HOST`와 `DB_PORT` 확인

5. **네트워크 연결 테스트**:
   ```bash
   # EC2에서 RDS 연결 테스트
   telnet your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com 3307
   # 또는
   nc -zv your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com 3307
   ```

6. **VPC 및 서브넷 확인**:
   - EC2와 RDS가 같은 VPC에 있는지 확인
   - 서로 다른 VPC인 경우 VPC Peering 또는 다른 연결 방법 필요

### 포트 문제

**증상**: 애플리케이션에 접속할 수 없음

**해결 방법**:

1. **EC2 보안 그룹 확인**:
   - HTTP(80), HTTPS(443), 커스텀 TCP(3000) 규칙 확인
   - 소스: `0.0.0.0/0` (모든 IP) 또는 특정 IP

2. **애플리케이션 포트 확인**:
   ```bash
   # EC2에서 실행 중인 포트 확인
   sudo netstat -tlnp | grep 3000
   # 또는
   sudo ss -tlnp | grep 3000
   
   # PM2 상태 확인
   pm2 status
   ```

3. **Elastic Beanstalk**:
   - 포트는 `process.env.PORT` 사용 (자동 할당)
   - 로드 밸런서에서 포트 매핑 확인

4. **Nginx 프록시 문제**:
   ```bash
   # Nginx 설정 테스트
   sudo nginx -t
   
   # Nginx 재시작
   sudo systemctl restart nginx
   
   # Nginx 에러 로그 확인
   sudo tail -f /var/log/nginx/error.log
   ```

### 메모리 부족

**증상**: 애플리케이션이 갑자기 종료되거나 느려짐

**해결 방법**:

1. **메모리 사용량 확인**:
   ```bash
   free -h
   # 또는
   pm2 monit
   ```

2. **EC2 인스턴스 크기 업그레이드**:
   - t2.micro (1GB RAM) → t2.small (2GB RAM)
   - EC2 콘솔 → 인스턴스 → 작업 → 인스턴스 설정 → 인스턴스 크기 변경

3. **PM2 메모리 제한 설정**:
   ```bash
   # 메모리 사용량 제한
   pm2 start server.js --name todo-app --max-memory-restart 500M
   pm2 save
   ```

4. **Node.js 가비지 컬렉션 최적화**:
   ```bash
   pm2 start server.js --name todo-app --node-args="--max-old-space-size=512"
   ```

5. **스왑 메모리 추가** (임시 해결책):
   ```bash
   # 2GB 스왑 파일 생성 (Ubuntu)
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

### 애플리케이션 오류

**증상**: 500 에러 또는 애플리케이션이 시작되지 않음

**해결 방법**:

1. **로그 확인**:
   ```bash
   # PM2 로그
   pm2 logs todo-app --lines 100
   
   # 또는 직접 실행하여 오류 확인
   node server.js
   ```

2. **의존성 확인**:
   ```bash
   npm install --production
   ```

3. **환경변수 확인**:
   ```bash
   # .env 파일 확인
   cat .env
   
   # 환경변수가 올바르게 로드되는지 확인
   node -e "require('dotenv').config(); console.log(process.env.DB_HOST);"
   ```

4. **데이터베이스 테이블 확인**:
   ```sql
   -- RDS에 접속하여 확인
   USE todo;
   SHOW TABLES;
   SELECT COUNT(*) FROM todos;
   ```

### EC2 연결 문제

**증상**: SSH로 EC2에 접속할 수 없음

**해결 방법**:

1. **보안 그룹 확인**:
   - SSH(포트 22) 규칙이 존재하는지 확인
   - 소스: 내 IP 또는 특정 IP

2. **키 파일 권한 확인** (Linux/macOS):
   ```bash
   chmod 400 todo-app-key.pem
   ```

3. **퍼블릭 IP 확인**:
   - EC2 콘솔에서 현재 퍼블릭 IP 확인 (재시작 시 변경됨)

4. **Elastic IP 사용** (권장):
   - EC2 콘솔 → Elastic IPs → 할당
   - 작업 → Elastic IP 주소 연결 → 인스턴스 선택
   - 이후 퍼블릭 IP가 변경되지 않음

### RDS 연결 타임아웃

**증상**: `ETIMEDOUT` 또는 연결이 느림

**해결 방법**:

1. **RDS와 EC2가 같은 리전에 있는지 확인**

2. **보안 그룹 규칙 확인**:
   - RDS 보안 그룹에 EC2 보안 그룹 또는 IP 추가

3. **네트워크 ACL 확인**:
   - VPC → 네트워크 ACLs에서 규칙 확인

4. **연결 풀 설정 조정**:
   ```javascript
   // server.js에서 connectionLimit 줄이기
   connectionLimit: 3  // 5에서 3으로
   ```

---

## 비용 예상

### 프리티어 사용 시 (월간, 첫 12개월)

| 서비스 | 인스턴스 타입 | 비용 | 비고 |
|--------|--------------|------|------|
| EC2 | t2.micro | $0 | 750시간/월 |
| RDS | db.t3.micro | $0 | 750시간/월 |
| 데이터 전송 | - | $0 | 1GB/월 (아웃바운드) |
| **총계** | - | **$0** | - |

### 프리티어 종료 후 (소규모 운영)

| 서비스 | 인스턴스 타입 | 비용/월 | 비고 |
|--------|--------------|---------|------|
| EC2 | t2.micro | 약 $8-10 | 온디맨드 |
| EC2 | t3.micro | 약 $7-9 | 온디맨드 (더 효율적) |
| RDS | db.t3.micro | 약 $15-18 | 온디맨드, 20GB 스토리지 포함 |
| Elastic IP | - | $0 | 인스턴스가 실행 중일 때만 무료 |
| 데이터 전송 | - | $0.09/GB | 첫 1GB 이후 |
| **총계 (최소)** | - | **약 $22-28** | t2.micro + db.t3.micro |

### 비용 절감 팁

1. **예약 인스턴스 사용**: 약 40% 할인 (1년 약정)
2. **스팟 인스턴스**: 약 70% 할인 (작업이 중단될 수 있음)
3. **불필요한 인스턴스 중지**: 개발 환경은 사용 후 중지
4. **CloudWatch 모니터링**: 비용 알림 설정
5. **S3 스토리지 클래스**: 자주 사용하지 않는 데이터는 Glacier 사용

---

## 추가 리소스

### 공식 문서
- [AWS RDS 문서](https://docs.aws.amazon.com/rds/)
- [AWS Elastic Beanstalk 문서](https://docs.aws.amazon.com/elasticbeanstalk/)
- [AWS EC2 문서](https://docs.aws.amazon.com/ec2/)
- [AWS App Runner 문서](https://docs.aws.amazon.com/apprunner/)
- [AWS 보안 그룹 가이드](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/working-with-security-groups.html)

### 유용한 도구
- [AWS Pricing Calculator](https://calculator.aws/) - 비용 계산기
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) - 아키텍처 모범 사례
- [PM2 문서](https://pm2.keymetrics.io/docs/) - 프로세스 관리
- [Nginx 문서](https://nginx.org/en/docs/) - 웹 서버 설정

### 학습 자료
- [AWS 공식 학습 경로](https://aws.amazon.com/training/)
- [AWS 프리티어 가이드](https://aws.amazon.com/ko/free/)

---

## 요약

이 가이드를 통해 다음을 완료했습니다:

✅ AWS RDS 데이터베이스 생성 및 설정  
✅ EC2 인스턴스 생성 및 접속  
✅ Node.js 애플리케이션 배포  
✅ PM2로 프로세스 관리  
✅ Nginx 리버스 프록시 설정 (선택사항)  
✅ 보안 그룹 및 네트워크 설정  
✅ 애플리케이션 모니터링 및 로그 확인  

**문제가 발생하면 [트러블슈팅](#트러블슈팅) 섹션을 참고하세요.**

배포가 완료되면 브라우저에서 `http://your-server-url`로 접속하여 Todo 애플리케이션을 사용할 수 있습니다! 🎉

