const express = require('express');
const cors = require('cors');
const mariadb = require('mariadb');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 미들웨어
app.use(cors());
app.use(express.json());
app.use(express.static('.')); // 정적 파일 제공 (프론트엔드)

// MariaDB 연결 설정
const pool = mariadb.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 3307,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'qwer1257',
  database: process.env.DB_NAME || 'todo',
  connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT) || 5
});

// 데이터베이스 연결 테스트
pool.getConnection()
  .then(conn => {
    console.log('✅ MariaDB 연결 성공');
    conn.release();
  })
  .catch(err => {
    console.error('❌ MariaDB 연결 실패:', err);
  });

// BIGINT를 Number로 변환하는 헬퍼 함수
function convertBigIntToNumber(obj) {
  if (obj === null || obj === undefined) return obj;
  if (typeof obj === 'bigint') return Number(obj);
  if (Array.isArray(obj)) return obj.map(convertBigIntToNumber);
  if (typeof obj === 'object') {
    const converted = {};
    for (const key in obj) {
      converted[key] = convertBigIntToNumber(obj[key]);
    }
    return converted;
  }
  return obj;
}

// 데이터베이스 에러 메시지 생성 함수
function getDbErrorMessage(err) {
  if (err.code === 'ER_NO_SUCH_TABLE') {
    return '데이터베이스 테이블이 없습니다. database.sql 파일을 실행해주세요.';
  }
  if (err.code === 'ER_BAD_DB_ERROR') {
    return '데이터베이스가 없습니다. database.sql 파일을 실행해주세요.';
  }
  if (err.code === 'ECONNREFUSED' || err.code === 'ETIMEDOUT') {
    return '데이터베이스 연결에 실패했습니다. MariaDB가 실행 중인지 확인해주세요.';
  }
  return err.message || '데이터베이스 작업 중 오류가 발생했습니다.';
}

// 모든 할일 조회
app.get('/api/todos', async (req, res) => {
  let conn;
  try {
    conn = await pool.getConnection();
    const rows = await conn.query('SELECT * FROM todos ORDER BY createdDate DESC');
    res.json(convertBigIntToNumber(rows));
  } catch (err) {
    console.error('할일 조회 오류:', err);
    res.status(500).json({ error: getDbErrorMessage(err), details: err.message });
  } finally {
    if (conn) conn.release();
  }
});

// 특정 할일 조회
app.get('/api/todos/:id', async (req, res) => {
  let conn;
  try {
    conn = await pool.getConnection();
    const rows = await conn.query('SELECT * FROM todos WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: '할일을 찾을 수 없습니다.' });
    }
    res.json(convertBigIntToNumber(rows[0]));
  } catch (err) {
    console.error('할일 조회 오류:', err);
    res.status(500).json({ error: getDbErrorMessage(err), details: err.message });
  } finally {
    if (conn) conn.release();
  }
});

// 할일 추가
app.post('/api/todos', async (req, res) => {
  let conn;
  try {
    const { text, details, dueDate } = req.body;
    
    if (!text || text.trim() === '') {
      return res.status(400).json({ error: '할일 내용을 입력해주세요.' });
    }

    const createdDate = Date.now();
    const id = createdDate;

    conn = await pool.getConnection();
    await conn.query(
      'INSERT INTO todos (id, text, details, completed, createdDate, dueDate) VALUES (?, ?, ?, ?, ?, ?)',
      [id, text.trim(), details || null, false, createdDate, dueDate || null]
    );

    const newTodo = await conn.query('SELECT * FROM todos WHERE id = ?', [id]);
    res.status(201).json(convertBigIntToNumber(newTodo[0]));
  } catch (err) {
    console.error('할일 추가 오류:', err);
    res.status(500).json({ error: getDbErrorMessage(err), details: err.message });
  } finally {
    if (conn) conn.release();
  }
});

// 할일 수정
app.put('/api/todos/:id', async (req, res) => {
  let conn;
  try {
    const { text, details, completed, dueDate } = req.body;
    const id = parseInt(req.params.id);

    conn = await pool.getConnection();
    
    // 기존 할일 확인
    const existing = await conn.query('SELECT * FROM todos WHERE id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ error: '할일을 찾을 수 없습니다.' });
    }

    const updateData = {};
    if (text !== undefined) updateData.text = text.trim();
    if (details !== undefined) updateData.details = details || null;
    if (completed !== undefined) {
      updateData.completed = completed;
      if (completed && !existing[0].completedDate) {
        updateData.completedDate = Date.now();
      } else if (!completed) {
        updateData.completedDate = null;
      }
    }
    if (dueDate !== undefined) updateData.dueDate = dueDate || null;
    
    updateData.modifiedDate = Date.now();

    const setClause = Object.keys(updateData).map(key => `${key} = ?`).join(', ');
    const values = [...Object.values(updateData), id];

    await conn.query(`UPDATE todos SET ${setClause} WHERE id = ?`, values);

    const updatedTodo = await conn.query('SELECT * FROM todos WHERE id = ?', [id]);
    res.json(convertBigIntToNumber(updatedTodo[0]));
  } catch (err) {
    console.error('할일 수정 오류:', err);
    res.status(500).json({ error: getDbErrorMessage(err), details: err.message });
  } finally {
    if (conn) conn.release();
  }
});

// 할일 삭제
app.delete('/api/todos/:id', async (req, res) => {
  let conn;
  try {
    const id = parseInt(req.params.id);

    conn = await pool.getConnection();
    const result = await conn.query('DELETE FROM todos WHERE id = ?', [id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: '할일을 찾을 수 없습니다.' });
    }

    res.json({ message: '할일이 삭제되었습니다.' });
  } catch (err) {
    console.error('할일 삭제 오류:', err);
    res.status(500).json({ error: getDbErrorMessage(err), details: err.message });
  } finally {
    if (conn) conn.release();
  }
});

// 완료된 할일 모두 삭제
app.delete('/api/todos', async (req, res) => {
  let conn;
  try {
    conn = await pool.getConnection();
    const result = await conn.query('DELETE FROM todos WHERE completed = true');
    res.json({ message: `${result.affectedRows}개의 완료된 할일이 삭제되었습니다.` });
  } catch (err) {
    console.error('완료된 할일 삭제 오류:', err);
    res.status(500).json({ error: getDbErrorMessage(err), details: err.message });
  } finally {
    if (conn) conn.release();
  }
});

// 서버 시작
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 서버가 http://0.0.0.0:${PORT} 에서 실행 중입니다.`);
  console.log(`🌐 외부 접속: http://your-ec2-public-ip:${PORT}`);
});

