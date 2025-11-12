# 문제 해결 가이드

## 할일 추가 실패 오류

할일 추가가 실패하는 경우 다음을 확인하세요:

### 1. 데이터베이스가 생성되었는지 확인

MariaDB에 접속하여 데이터베이스와 테이블이 존재하는지 확인:

```sql
-- MariaDB 클라이언트에서 실행
SHOW DATABASES;
USE todo;
SHOW TABLES;
DESCRIBE todos;
```

데이터베이스나 테이블이 없다면 `database.sql` 파일을 실행하세요:

```bash
mysql -u root -p1234 -P 3307 < database.sql
```

또는 MariaDB 클라이언트에서 직접:

```sql
CREATE DATABASE IF NOT EXISTS todo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE todo;
CREATE TABLE IF NOT EXISTS todos (
    id BIGINT PRIMARY KEY,
    text VARCHAR(500) NOT NULL,
    details TEXT,
    completed BOOLEAN DEFAULT FALSE,
    createdDate BIGINT NOT NULL,
    completedDate BIGINT,
    dueDate BIGINT,
    modifiedDate BIGINT,
    INDEX idx_createdDate (createdDate),
    INDEX idx_completed (completed),
    INDEX idx_dueDate (dueDate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 2. MariaDB 서버가 실행 중인지 확인

Windows 서비스에서 MariaDB가 실행 중인지 확인하거나:

```bash
# PowerShell에서
Get-Service | Where-Object {$_.Name -like "*mariadb*" -or $_.Name -like "*mysql*"}
```

### 3. 서버가 실행 중인지 확인

서버가 실행 중이어야 합니다:

```bash
npm.cmd start
```

또는 개발 모드:

```bash
npm.cmd run dev
```

서버 콘솔에서 다음 메시지가 보여야 합니다:
- `✅ MariaDB 연결 성공`
- `🚀 서버가 http://localhost:3000 에서 실행 중입니다.`

### 4. 연결 정보 확인

`server.js` 파일의 데이터베이스 연결 설정을 확인하세요:

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

설정이 다르다면 수정하세요.

### 5. 브라우저 콘솔 확인

브라우저 개발자 도구(F12)의 콘솔 탭에서 자세한 오류 메시지를 확인하세요.

### 6. 서버 로그 확인

서버를 실행한 터미널에서 오류 메시지를 확인하세요. 다음과 같은 오류가 나타날 수 있습니다:

- `ER_BAD_DB_ERROR`: 데이터베이스가 없음
- `ER_NO_SUCH_TABLE`: 테이블이 없음
- `ECONNREFUSED`: MariaDB 서버에 연결할 수 없음

## 일반적인 오류 메시지

### "데이터베이스가 없습니다"
→ `database.sql` 파일을 실행하여 데이터베이스를 생성하세요.

### "데이터베이스 테이블이 없습니다"
→ `database.sql` 파일을 실행하여 테이블을 생성하세요.

### "데이터베이스 연결에 실패했습니다"
→ MariaDB 서버가 실행 중인지 확인하세요.

### "서버에 연결할 수 없습니다"
→ 서버가 실행 중인지 확인하세요 (`npm.cmd start`).

