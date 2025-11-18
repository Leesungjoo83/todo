# Todo 애플리케이션

할일 목록을 관리하는 웹 애플리케이션입니다.

## 기술 스택

### 프론트엔드
- HTML, CSS, JavaScript
- SheetJS (엑셀 내보내기)

### 백엔드
- Node.js (>=18.0.0)
- Express
- MariaDB/MySQL

## 빠른 시작

### 1. 의존성 설치

```bash
npm install
```

**Windows PowerShell 실행 정책 오류 시:**
- CMD 사용 (권장) 또는 `npm.cmd install` 실행

### 2. 데이터베이스 설정

`.env` 파일을 생성하고 데이터베이스 정보를 설정하세요:

```bash
cp env.example .env
# .env 파일 편집
```

로컬 MariaDB 사용 시:
```bash
mysql -u root -p -P 3307 < database.sql
```

### 3. 서버 실행

```bash
npm start        # 프로덕션 모드
npm run dev      # 개발 모드 (nodemon)
```

서버는 `http://localhost:3000`에서 실행됩니다.

## 주요 기능

- 할일 추가, 수정, 삭제
- 완료 상태 토글
- 완료 예정일 설정
- 세부내용 추가
- 필터링 (전체/진행중/완료)
- 기간 필터링 (전체/주간/월간)
- 달력 뷰 (월간 필터 시)
- JSON/Excel 파일로 내보내기
- JSON 파일에서 불러오기

## API 엔드포인트

- `GET /api/todos` - 모든 할일 조회
- `GET /api/todos/:id` - 특정 할일 조회
- `POST /api/todos` - 할일 추가
- `PUT /api/todos/:id` - 할일 수정
- `DELETE /api/todos/:id` - 할일 삭제
- `DELETE /api/todos` - 완료된 할일 모두 삭제

## AWS 배포

### 빠른 배포 (EC2에 이미 설치된 경우)

```bash
npm run deploy:first  # 첫 배포
npm run deploy        # 일반 배포
```

### 상세 가이드

- **[DEPLOY_QUICK.md](./DEPLOY_QUICK.md)** - 빠른 배포 가이드
- **[AWS_DEPLOY.md](./AWS_DEPLOY.md)** - 상세한 AWS 배포 가이드 (EC2, Elastic Beanstalk, App Runner, Docker)

## 문제 해결

문제가 발생하면 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** 문서를 참고하세요.

## 문서 구조

- `README.md` - 프로젝트 소개 및 빠른 시작
- `AWS_DEPLOY.md` - AWS 배포 상세 가이드
- `DEPLOY_QUICK.md` - 빠른 배포 가이드
- `TROUBLESHOOTING.md` - 문제 해결 가이드 (로컬/배포/RDS)