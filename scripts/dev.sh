#!/bin/bash

# Modern ShortLink 开发环境启动脚本

set -e

echo "🚀 启动 Modern ShortLink 开发环境..."

# 检查环境变量文件
check_env_files() {
    if [ ! -f "backend/.env" ]; then
        echo "❌ 后端环境变量文件不存在，请先运行 ./scripts/setup.sh"
        exit 1
    fi
    
    if [ ! -f "frontend/.env" ]; then
        echo "❌ 前端环境变量文件不存在，请先运行 ./scripts/setup.sh"
        exit 1
    fi
}

# 启动数据库服务
start_database() {
    echo "🗄️ 启动数据库服务..."
    docker-compose up -d postgres redis
    
    echo "⏳ 等待数据库启动..."
    sleep 5
    
    # 检查数据库连接
    until docker-compose exec -T postgres pg_isready -U shortlink -d shortlink; do
        echo "⏳ 等待 PostgreSQL 启动..."
        sleep 2
    done
    
    echo "✅ 数据库服务已启动"
}

# 运行数据库迁移
run_migrations() {
    echo "📊 运行数据库迁移..."
    cd backend
    npx prisma migrate dev
    npx prisma generate
    cd ..
    echo "✅ 数据库迁移完成"
}

# 启动开发服务器
start_dev_servers() {
    echo "🚀 启动开发服务器..."
    
    # 使用 concurrently 同时启动前后端
    npm run dev
}

# 主函数
main() {
    check_env_files
    start_database
    run_migrations
    start_dev_servers
}

# 运行主函数
main
