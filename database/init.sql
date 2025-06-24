-- 短链接管理系统数据库初始化脚本
-- 创建数据库
CREATE DATABASE IF NOT EXISTS shortlink CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE shortlink;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL COMMENT '邮箱',
    password VARCHAR(255) NOT NULL COMMENT '密码哈希',
    username VARCHAR(100) NOT NULL COMMENT '用户名',
    role ENUM('admin', 'user') DEFAULT 'user' COMMENT '用户角色',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '用户状态',
    avatar VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
    last_login_at TIMESTAMP NULL COMMENT '最后登录时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 短链接表
CREATE TABLE IF NOT EXISTS links (
    id INT PRIMARY KEY AUTO_INCREMENT,
    short_code VARCHAR(10) UNIQUE NOT NULL COMMENT '短链接代码',
    original_url TEXT NOT NULL COMMENT '原始URL',
    user_id INT NOT NULL COMMENT '创建用户ID',
    title VARCHAR(255) DEFAULT NULL COMMENT '链接标题',
    description TEXT DEFAULT NULL COMMENT '链接描述',
    domain VARCHAR(255) DEFAULT 'localhost:9848' COMMENT '短链接域名',
    expires_at TIMESTAMP NULL COMMENT '过期时间',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    click_count INT DEFAULT 0 COMMENT '点击次数',
    password VARCHAR(255) DEFAULT NULL COMMENT '访问密码',
    tags JSON DEFAULT NULL COMMENT '标签',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_short_code (short_code),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at),
    INDEX idx_created_at (created_at),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='短链接表';

-- 访问统计表
CREATE TABLE IF NOT EXISTS link_stats (
    id INT PRIMARY KEY AUTO_INCREMENT,
    link_id INT NOT NULL COMMENT '链接ID',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    referer TEXT COMMENT '来源页面',
    country VARCHAR(100) COMMENT '国家',
    region VARCHAR(100) COMMENT '地区',
    city VARCHAR(100) COMMENT '城市',
    device_type VARCHAR(50) COMMENT '设备类型',
    browser VARCHAR(100) COMMENT '浏览器',
    os VARCHAR(100) COMMENT '操作系统',
    clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '点击时间',
    FOREIGN KEY (link_id) REFERENCES links(id) ON DELETE CASCADE,
    INDEX idx_link_id (link_id),
    INDEX idx_clicked_at (clicked_at),
    INDEX idx_ip_address (ip_address),
    INDEX idx_country (country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='访问统计表';

-- 系统配置表
CREATE TABLE IF NOT EXISTS system_config (
    id INT PRIMARY KEY AUTO_INCREMENT,
    config_key VARCHAR(100) UNIQUE NOT NULL COMMENT '配置键',
    config_value TEXT COMMENT '配置值',
    config_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string' COMMENT '配置类型',
    description VARCHAR(255) COMMENT '配置描述',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_config_key (config_key),
    INDEX idx_is_public (is_public)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 用户会话表
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT '用户ID',
    session_token VARCHAR(255) UNIQUE NOT NULL COMMENT '会话令牌',
    expires_at TIMESTAMP NOT NULL COMMENT '过期时间',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户会话表';

-- 插入默认管理员用户
-- 密码: admin123456 (BCrypt加密)
INSERT IGNORE INTO users (email, password, username, role) VALUES 
('admin@shortlink.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', '系统管理员', 'admin');

-- 插入默认系统配置
INSERT IGNORE INTO system_config (config_key, config_value, config_type, description, is_public) VALUES 
('site_name', '短链接管理系统', 'string', '网站名称', TRUE),
('site_description', '专业的短链接管理平台', 'string', '网站描述', TRUE),
('default_domain', 'localhost:9848', 'string', '默认短链接域名', FALSE),
('short_link_min_length', '4', 'number', '短链接最小长度', FALSE),
('short_link_max_length', '10', 'number', '短链接最大长度', FALSE),
('allow_custom_code', 'true', 'boolean', '允许自定义短链接代码', FALSE),
('require_login', 'true', 'boolean', '是否需要登录才能创建链接', FALSE),
('max_links_per_user', '1000', 'number', '每个用户最大链接数', FALSE),
('enable_analytics', 'true', 'boolean', '启用访问统计', FALSE),
('enable_password_protection', 'true', 'boolean', '启用密码保护', FALSE);
