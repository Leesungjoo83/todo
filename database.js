// 데이터베이스 연결 확인 스크립트
const mariadb = require('mariadb');

const pool = mariadb.createPool({
  host: 'localhost',
  port: 3307,
  user: 'root',
  password: 'qwer1257',
  database: 'todo',
  connectionLimit: 5
});

async function checkDatabase() {
  let conn;
  try {
    console.log('데이터베이스 연결 시도 중...');
    conn = await pool.getConnection();
    console.log('✅ 데이터베이스 연결 성공!');
    
    // 테이블 확인
    const tables = await conn.query("SHOW TABLES LIKE 'todos'");
    if (tables.length === 0) {
      console.log('❌ todos 테이블이 없습니다.');
      console.log('database.sql 파일을 실행하여 테이블을 생성하세요.');
    } else {
      console.log('✅ todos 테이블이 존재합니다.');
      
      // 테이블 구조 확인
      const columns = await conn.query("DESCRIBE todos");
      console.log('\n테이블 구조:');
      console.table(columns);
      
      // 데이터 개수 확인
      const count = await conn.query("SELECT COUNT(*) as count FROM todos");
      console.log(`\n현재 할일 개수: ${count[0].count}`);
    }
    
  } catch (err) {
    console.error('❌ 오류 발생:', err.message);
    console.error('오류 코드:', err.code);
    
    if (err.code === 'ER_BAD_DB_ERROR') {
      console.log('\n해결 방법:');
      console.log('1. MariaDB에 접속하여 다음 명령을 실행하세요:');
      console.log('   CREATE DATABASE IF NOT EXISTS todo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
      console.log('2. 또는 database.sql 파일을 실행하세요.');
    } else if (err.code === 'ER_NO_SUCH_TABLE') {
      console.log('\n해결 방법:');
      console.log('database.sql 파일을 실행하여 테이블을 생성하세요.');
    } else if (err.code === 'ECONNREFUSED' || err.code === 'ETIMEDOUT') {
      console.log('\n해결 방법:');
      console.log('1. MariaDB 서버가 실행 중인지 확인하세요.');
      console.log('2. 포트 3307이 올바른지 확인하세요.');
      console.log('3. 방화벽 설정을 확인하세요.');
    }
  } finally {
    if (conn) conn.release();
    await pool.end();
  }
}

checkDatabase();

