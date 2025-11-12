# Todo 애플리케이션

할일 목록을 관리하는 웹 애플리케이션입니다.

## 기술 스택

### 프론트엔드
- HTML, CSS, JavaScript
- SheetJS (엑셀 내보내기)

### 백엔드
- Node.js
- Express
- MariaDB

## 설치 및 실행

### 1. 의존성 설치

```bash
npm install
```

**PowerShell 실행 정책 오류가 발생하는 경우:**

Windows PowerShell에서 실행 정책 오류가 발생하면 다음 방법 중 하나를 사용하세요:

**방법 1: CMD 사용 (권장)**
- PowerShell 대신 명령 프롬프트(CMD)를 사용하세요
- CMD에서는 실행 정책 제한이 없습니다

**방법 2: 실행 정책 변경 (관리자 권한 필요)**
```powershell
# 관리자 권한으로 PowerShell 실행 후
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**방법 3: npm.cmd 직접 사용**
```powershell
npm.cmd install
```

### 2. 데이터베이스 설정

MariaDB에 접속하여 `database.sql` 파일을 실행하세요:

```bash
mysql -u root -p -P 3307 < database.sql
```

또는 MariaDB 클라이언트에서 직접 실행:

```sql
CREATE DATABASE IF NOT EXISTS todo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE todo;
-- database.sql 파일의 나머지 내용 실행
```

### 3. 서버 실행

```bash
npm start
```

개발 모드 (nodemon 사용):

```bash
npm run dev
```

서버는 기본적으로 `http://localhost:3000`에서 실행됩니다.

## 데이터베이스 설정

- **데이터베이스 이름**: todo
- **사용자**: root
- **비밀번호**: 1234
- **포트**: 3307

설정을 변경하려면 `server.js` 파일의 MariaDB 연결 설정을 수정하세요.

## API 엔드포인트

- `GET /api/todos` - 모든 할일 조회
- `GET /api/todos/:id` - 특정 할일 조회
- `POST /api/todos` - 할일 추가
- `PUT /api/todos/:id` - 할일 수정
- `DELETE /api/todos/:id` - 할일 삭제
- `DELETE /api/todos` - 완료된 할일 모두 삭제

## 기능

- 할일 추가, 수정, 삭제
- 완료 상태 토글
- 완료 예정일 설정
- 세부내용 추가
- 필터링 (전체/진행중/완료)
- 기간 필터링 (전체/주간/월간)
- 달력 뷰 (월간 필터 시)
- JSON/Excel 파일로 내보내기
- JSON 파일에서 불러오기
