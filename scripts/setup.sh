#!/bin/bash

# Modern ShortLink 项目初始化脚本

set -e

echo "🚀 开始初始化 Modern ShortLink 项目..."

# 检查必要的工具
check_requirements() {
    echo "📋 检查系统要求..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js 未安装，请先安装 Node.js 18+"
        exit 1
    fi
    
    echo "✅ 系统要求检查通过"
}

# 安装依赖
install_dependencies() {
    echo "📦 安装项目依赖..."
    
    # 安装根目录依赖
    npm install
    
    # 安装后端依赖
    echo "📦 安装后端依赖..."
    cd backend
    npm install
    cd ..
    
    # 安装前端依赖
    echo "📦 安装前端依赖..."
    cd frontend
    npm install
    cd ..
    
    echo "✅ 依赖安装完成"
}

# 设置环境变量
setup_environment() {
    echo "⚙️ 设置环境变量..."
    
    # 后端环境变量
    if [ ! -f "backend/.env" ]; then
        cat > backend/.env << EOF
# 环境配置
NODE_ENV=development
PORT=3000
HOST=0.0.0.0

# 数据库配置
DATABASE_URL=postgresql://shortlink:shortlink_password_2024@localhost:5432/shortlink

# Redis 配置
REDIS_URL=redis://:redis_password_2024@localhost:6379

# JWT 配置
JWT_SECRET=your_super_secret_jwt_key_2024_change_this_in_production
JWT_EXPIRES_IN=7d

# CORS 配置
CORS_ORIGIN=http://localhost:3001

# 限流配置
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW=900000

# 短链接配置
DEFAULT_DOMAIN=localhost:3000
SHORT_CODE_LENGTH=6

# 功能开关
ENABLE_ANALYTICS=true

# 日志配置
LOG_LEVEL=info
EOF
        echo "✅ 后端环境变量文件已创建"
    else
        echo "⚠️ 后端环境变量文件已存在，跳过创建"
    fi
    
    # 前端环境变量
    if [ ! -f "frontend/.env" ]; then
        cat > frontend/.env << EOF
# API 配置
VITE_API_URL=http://localhost:3000/api/v1

# 应用配置
VITE_APP_NAME=Modern ShortLink
VITE_APP_DESCRIPTION=现代化短链接系统
EOF
        echo "✅ 前端环境变量文件已创建"
    else
        echo "⚠️ 前端环境变量文件已存在，跳过创建"
    fi
}

# 构建 Docker 镜像
build_images() {
    echo "🐳 构建 Docker 镜像..."
    docker-compose build
    echo "✅ Docker 镜像构建完成"
}

# 启动服务
start_services() {
    echo "🚀 启动服务..."
    docker-compose up -d
    
    echo "⏳ 等待服务启动..."
    sleep 10
    
    # 检查服务状态
    echo "🔍 检查服务状态..."
    docker-compose ps
}

# 初始化数据库
init_database() {
    echo "🗄️ 初始化数据库..."
    
    # 等待数据库启动
    echo "⏳ 等待数据库启动..."
    sleep 5
    
    # 运行数据库迁移
    echo "📊 运行数据库迁移..."
    docker-compose exec backend npx prisma migrate deploy
    
    # 生成 Prisma 客户端
    echo "🔧 生成 Prisma 客户端..."
    docker-compose exec backend npx prisma generate
    
    # 运行种子数据
    echo "🌱 插入种子数据..."
    docker-compose exec backend npm run db:seed
    
    echo "✅ 数据库初始化完成"
}

# 显示完成信息
show_completion_info() {
    echo ""
    echo "🎉 Modern ShortLink 项目初始化完成！"
    echo ""
    echo "📋 服务信息:"
    echo "   前端界面: http://localhost:3001"
    echo "   后端API: http://localhost:3000"
    echo "   API文档: http://localhost:3000/docs"
    echo "   数据库: localhost:5432"
    echo "   Redis: localhost:6379"
    echo ""
    echo "🔑 默认账户:"
    echo "   管理员: admin@shortlink.com / admin123456"
    echo "   测试用户: test@shortlink.com / test123456"
    echo ""
    echo "🛠️ 常用命令:"
    echo "   启动服务: docker-compose up -d"
    echo "   停止服务: docker-compose down"
    echo "   查看日志: docker-compose logs -f"
    echo "   重启服务: docker-compose restart"
    echo ""
    echo "📚 更多信息请查看 README.md"
}

# 主函数
main() {
    check_requirements
    install_dependencies
    setup_environment
    build_images
    start_services
    init_database
    show_completion_info
}

# 运行主函数
main
