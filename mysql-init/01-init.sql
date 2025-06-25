-- 短链接数据库初始化脚本

-- 设置字符集
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 创建链接表
CREATE TABLE IF NOT EXISTS `links` (
  `id` int NOT NULL AUTO_INCREMENT,
  `short_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `original_url` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `click_count` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_short_code` (`short_code`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_click_count` (`click_count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='短链接表';

-- 创建点击记录表
CREATE TABLE IF NOT EXISTS `clicks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `short_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `referer` text COLLATE utf8mb4_unicode_ci,
  `clicked_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_short_code` (`short_code`),
  KEY `idx_clicked_at` (`clicked_at`),
  KEY `idx_ip_address` (`ip_address`),
  CONSTRAINT `fk_clicks_short_code` FOREIGN KEY (`short_code`) REFERENCES `links` (`short_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='点击记录表';

-- 插入示例数据（可选）
INSERT IGNORE INTO `links` (`short_code`, `original_url`, `title`, `click_count`) VALUES
('demo', 'https://www.example.com', '示例网站', 0),
('github', 'https://github.com', 'GitHub', 0);

SET FOREIGN_KEY_CHECKS = 1;
