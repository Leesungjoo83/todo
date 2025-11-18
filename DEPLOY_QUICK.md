# 빠른 배포 가이드

AWS EC2에 이미 프로젝트가 설치되어 있고, Node.js와 npm이 설치되어 있는 경우 이 가이드를 사용하세요.

## 🚀 한 번에 배포하기

### 첫 배포 (초기 설정)

```bash
# 스크립트 실행 권한 부여
chmod +x deploy-first-time.sh

# 첫 배포 실행
./deploy-first-time.sh
```

또는 npm 스크립트 사용:
```bash
npm run deploy:first
```

**첫 배포 시 자동으로 수행되는 작업:**
1. ✅ Node.js 및 npm 확인
2. ✅ Git 확인
3. ✅ 프로젝트 디렉토리 생성
4. ✅ Git에서 프로젝트 클론
5. ✅ .env 파일 생성 (env.example 기반)
6. ✅ 의존성 설치 (npm install)
7. ✅ PM2 설치
8. ✅ PM2 자동 시작 설정
9. ✅ 애플리케이션 시작
10. ✅ 배포 상태 확인
11. ✅ 헬스 체크
12. ✅ 로그 출력

### 일반 배포 (이후 업데이트)

코드가 업데이트되었을 때:

```bash
# 스크립트 실행 권한 부여 (처음 한 번만)
chmod +x deploy.sh

# 배포 실행
./deploy.sh
```

또는 npm 스크립트 사용:
```bash
npm run deploy
```

**일반 배포 시 자동으로 수행되는 작업:**
1. ✅ Git에서 최신 코드 가져오기
2. ✅ 의존성 업데이트 (npm install)
3. ✅ PM2로 애플리케이션 재시작
4. ✅ 배포 상태 확인
5. ✅ 헬스 체크
6. ✅ 로그 출력

## 📋 필수 확인사항

### 배포 전 확인

1. **.env 파일 확인**
   ```bash
   cat .env
   ```
   다음 항목이 올바르게 설정되어 있는지 확인:
   - `DB_HOST`: RDS 엔드포인트
   - `DB_PORT`: 3307
   - `DB_USER`: root
   - `DB_PASSWORD`: 비밀번호
   - `DB_NAME`: todo

2. **데이터베이스 연결 확인**
   ```bash
   # RDS 연결 테스트
   mysql -h your-rds-endpoint.xxxxx.ap-northeast-2.rds.amazonaws.com \
         -P 3307 \
         -u root \
         -p \
         -e "USE todo; SELECT COUNT(*) FROM todos;"
   ```

3. **포트 확인**
   ```bash
   # 포트 3000이 사용 중인지 확인
   sudo netstat -tlnp | grep 3000
   ```

## 🔧 문제 해결

### 배포 실패 시

1. **로그 확인**
   ```bash
   pm2 logs todo-app --lines 50
   ```

2. **PM2 상태 확인**
   ```bash
   pm2 status
   ```

3. **애플리케이션 재시작**
   ```bash
   pm2 restart todo-app
   ```

4. **수동으로 재시작**
   ```bash
   pm2 stop todo-app
   pm2 start server.js --name todo-app
   ```

### .env 파일 수정 후

```bash
# PM2 재시작 (환경변수 반영)
pm2 restart todo-app --update-env
```

### Git 업데이트 실패 시

```bash
# 수동으로 업데이트
cd ~/todo-app
git pull origin main
npm install --production
pm2 restart todo-app
```

## 📊 배포 후 확인

### 애플리케이션 상태 확인

```bash
# PM2 상태
pm2 status

# 실시간 모니터링
pm2 monit

# 로그 확인
pm2 logs todo-app

# 최근 50줄 로그
pm2 logs todo-app --lines 50
```

### API 테스트

```bash
# 로컬에서 테스트
curl http://localhost:3000/api/todos

# 외부에서 테스트 (EC2 퍼블릭 IP 사용)
curl http://your-ec2-public-ip/api/todos
```

### 브라우저에서 확인

- 로컬: `http://localhost:3000`
- 외부: `http://your-ec2-public-ip` 또는 `http://your-domain.com`

## 🎯 빠른 참조

### 자주 사용하는 명령어

```bash
# 배포
./deploy.sh

# 상태 확인
pm2 status

# 로그 보기
pm2 logs todo-app

# 재시작
pm2 restart todo-app

# 중지
pm2 stop todo-app

# 시작
pm2 start todo-app

# 모니터링
pm2 monit

# 환경변수 업데이트 후 재시작
pm2 restart todo-app --update-env
```

### Git 관련

```bash
# 최신 코드 가져오기
git pull origin main

# 변경사항 확인
git status

# 로그 확인
git log --oneline -10
```

## 💡 팁

1. **자동 배포**: GitHub Actions나 AWS CodePipeline을 사용하면 더 자동화할 수 있습니다.

2. **백업**: 배포 전 중요한 변경사항은 백업하세요.

3. **점진적 배포**: 큰 변경사항은 단계적으로 배포하세요.

4. **모니터링**: CloudWatch나 PM2 Plus를 사용하여 모니터링하세요.

5. **로그 관리**: PM2 로그는 자동으로 로테이션되지만, 필요시 로그 관리 설정을 추가하세요.

