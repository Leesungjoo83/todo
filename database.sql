-- 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS todo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 데이터베이스 사용
USE todo;

-- todos 테이블 생성
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

