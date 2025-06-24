#!/bin/bash

# 短链接管理系统快速部署脚本
# 使用Docker Hub预构建镜像，无需本地构建

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${2}${1}${NC}"
}

print_success() {
    print_message "$1" "$GREEN"
}

print_error() {
    print_message "$1" "$RED"
}

print_warning() {
    print_message "$1" "$YELLOW"
}

print_info() {
    print_message "$1" "$BLUE"
}

# 检查Docker环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        echo "安装指南: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        echo "安装指南: https://docs.docker.com/compose/install/"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker 服务未运行，请启动 Docker"
        exit 1
    fi

    print_success "✓ Docker 环境检查通过"
}

# 拉取最新镜像
pull_images() {
    print_info "拉取最新的Docker镜像..."
    
    docker pull nodesire7/shortlink-backend:latest
    docker pull nodesire7/shortlink-frontend:latest
    docker pull mysql:8.0
    docker pull redis:7-alpine
    
    print_success "✓ 镜像拉取完成"
}

# 创建必要的目录
create_directories() {
    print_info "创建必要的目录..."
    
    mkdir -p database
    mkdir -p logs
    
    print_success "✓ 目录创建完成"
}

# 下载数据库初始化脚本（如果不存在）
download_init_sql() {
    if [ ! -f "database/init.sql" ]; then
        print_info "下载数据库初始化脚本..."
        
        # 如果在Git仓库中，尝试从GitHub下载
        if [ -d ".git" ]; then
            REPO_URL=$(git config --get remote.origin.url)
            if [[ $REPO_URL == *"github.com"* ]]; then
                # 提取仓库信息
                REPO_PATH=$(echo $REPO_URL | sed 's/.*github.com[:/]\([^.]*\).*/\1/')
                curl -s "https://raw.githubusercontent.com/$REPO_PATH/main/database/init.sql" -o database/init.sql
                
                if [ $? -eq 0 ] && [ -s "database/init.sql" ]; then
                    print_success "✓ 数据库初始化脚本下载完成"
                else
                    print_warning "⚠ 无法下载初始化脚本，将创建基础脚本"
                    create_basic_init_sql
                fi
            else
                create_basic_init_sql
            fi
        else
            create_basic_init_sql
        fi
    else
        print_success "✓ 数据库初始化脚本已存在"
    fi
}

# 创建基础的数据库初始化脚本
create_basic_init_sql() {
    cat > database/init.sql << 'EOF'
-- 短链接管理系统数据库初始化脚本
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

-- 插入默认管理员用户
-- 密码: admin123456 (BCrypt加密)
INSERT IGNORE INTO users (email, password, username, role) VALUES 
('admin@shortlink.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', '系统管理员', 'admin');
EOF
    
    print_success "✓ 基础数据库初始化脚本创建完成"
}

# 启动服务
start_services() {
    print_info "启动短链接管理系统..."
    
    # 使用预构建镜像的compose文件
    docker-compose -f docker-compose.hub.yml up -d
    
    print_success "✓ 服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    print_info "等待服务启动..."
    
    # 等待后端服务
    for i in {1..30}; do
        if curl -f http://localhost:9848/health &> /dev/null; then
            print_success "✓ 后端服务已就绪"
            break
        fi
        
        if [ $i -eq 30 ]; then
            print_error "✗ 后端服务启动超时"
            docker-compose -f docker-compose.hub.yml logs backend
            exit 1
        fi
        
        sleep 2
    done
    
    # 等待前端服务
    for i in {1..15}; do
        if curl -f http://localhost:8848 &> /dev/null; then
            print_success "✓ 前端服务已就绪"
            break
        fi
        
        if [ $i -eq 15 ]; then
            print_error "✗ 前端服务启动超时"
            docker-compose -f docker-compose.hub.yml logs frontend
            exit 1
        fi
        
        sleep 2
    done
}

# 显示访问信息
show_access_info() {
    print_success "🎉 短链接管理系统部署成功！"
    echo
    print_info "访问地址："
    echo "  前端管理界面: http://localhost:8848"
    echo "  后端API接口: http://localhost:9848"
    echo "  API文档: http://localhost:9848/docs"
    echo
    print_info "默认管理员账号："
    echo "  邮箱: admin@shortlink.com"
    echo "  密码: admin123456"
    echo
    print_warning "⚠️  请及时修改默认密码和配置信息"
    echo
    print_info "常用命令："
    echo "  查看日志: docker-compose -f docker-compose.hub.yml logs -f"
    echo "  停止服务: docker-compose -f docker-compose.hub.yml down"
    echo "  重启服务: docker-compose -f docker-compose.hub.yml restart"
    echo "  查看状态: docker-compose -f docker-compose.hub.yml ps"
}

# 停止服务
stop_services() {
    print_info "停止服务..."
    docker-compose -f docker-compose.hub.yml down
    print_success "✓ 服务已停止"
}

# 显示帮助信息
show_help() {
    echo "短链接管理系统快速部署脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  start     启动服务 (默认)"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  logs      查看日志"
    echo "  status    查看服务状态"
    echo "  update    更新镜像并重启"
    echo "  help      显示帮助信息"
    echo
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            check_docker
            create_directories
            download_init_sql
            pull_images
            start_services
            wait_for_services
            show_access_info
            ;;
        stop)
            stop_services
            ;;
        restart)
            stop_services
            sleep 2
            start_services
            wait_for_services
            show_access_info
            ;;
        logs)
            docker-compose -f docker-compose.hub.yml logs -f
            ;;
        status)
            docker-compose -f docker-compose.hub.yml ps
            ;;
        update)
            print_info "更新镜像..."
            pull_images
            docker-compose -f docker-compose.hub.yml up -d
            wait_for_services
            show_access_info
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
