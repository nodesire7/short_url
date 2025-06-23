#!/bin/bash

# 生产环境部署脚本

set -e

echo "🚀 开始部署 Short URL 到生产环境..."

# 检查必要的环境变量
check_env_vars() {
    echo "📋 检查环境变量..."
    
    if [ -z "$DOCKER_USERNAME" ]; then
        echo "❌ 请设置 DOCKER_USERNAME 环境变量"
        exit 1
    fi
    
    if [ -z "$JWT_SECRET" ]; then
        echo "⚠️ 警告: 未设置 JWT_SECRET，将使用默认值"
    fi
    
    echo "✅ 环境变量检查完成"
}

# 拉取最新镜像
pull_images() {
    echo "📦 拉取最新 Docker 镜像..."
    
    docker pull $DOCKER_USERNAME/shorturl-backend:latest
    docker pull $DOCKER_USERNAME/shorturl-frontend:latest
    
    echo "✅ 镜像拉取完成"
}

# 停止现有服务
stop_services() {
    echo "🛑 停止现有服务..."
    
    docker-compose -f docker-compose.prod.yml down
    
    echo "✅ 服务已停止"
}

# 启动服务
start_services() {
    echo "🚀 启动生产服务..."
    
    docker-compose -f docker-compose.prod.yml up -d
    
    echo "⏳ 等待服务启动..."
    sleep 15
    
    echo "🔍 检查服务状态..."
    docker-compose -f docker-compose.prod.yml ps
}

# 运行数据库迁移
run_migrations() {
    echo "📊 运行数据库迁移..."
    
    # 等待数据库启动
    echo "⏳ 等待数据库启动..."
    sleep 10
    
    # 运行迁移
    docker-compose -f docker-compose.prod.yml exec -T backend npx prisma migrate deploy
    
    echo "✅ 数据库迁移完成"
}

# 健康检查
health_check() {
    echo "🔍 执行健康检查..."
    
    # 检查后端API
    for i in {1..30}; do
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            echo "✅ 后端API健康检查通过"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ 后端API健康检查失败"
            exit 1
        fi
        sleep 2
    done
    
    # 检查前端
    for i in {1..30}; do
        if curl -f http://localhost:3001 > /dev/null 2>&1; then
            echo "✅ 前端健康检查通过"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ 前端健康检查失败"
            exit 1
        fi
        sleep 2
    done
}

# 显示部署信息
show_deployment_info() {
    echo ""
    echo "🎉 Short URL 部署成功！"
    echo ""
    echo "📋 服务信息:"
    echo "   前端界面: http://localhost:3001"
    echo "   后端API: http://localhost:3000"
    echo "   API文档: http://localhost:3000/docs"
    echo ""
    echo "🔑 默认账户:"
    echo "   管理员: admin@shortlink.com / admin123456"
    echo "   测试用户: test@shortlink.com / test123456"
    echo ""
    echo "🛠️ 管理命令:"
    echo "   查看日志: docker-compose -f docker-compose.prod.yml logs -f"
    echo "   重启服务: docker-compose -f docker-compose.prod.yml restart"
    echo "   停止服务: docker-compose -f docker-compose.prod.yml down"
    echo ""
}

# 主函数
main() {
    check_env_vars
    pull_images
    stop_services
    start_services
    run_migrations
    health_check
    show_deployment_info
}

# 运行主函数
main
