#!/bin/bash

# Jump Jump 短链接系统启动脚本
# 确保数据持久化和服务稳定运行

set -e

echo "🚀 启动 Jump Jump 短链接系统..."

# 创建必要的目录
echo "📁 创建数据目录..."
mkdir -p data/redis
mkdir -p logs/api
mkdir -p logs/landing
mkdir -p config

# 设置目录权限
chmod 755 data/redis
chmod 755 logs/api
chmod 755 logs/landing

# 检查docker-compose文件
if [ ! -f "docker-compose.yaml" ]; then
    echo "❌ 错误: docker-compose.yaml 文件不存在"
    exit 1
fi

# 检查Redis配置文件
if [ ! -f "config/redis.conf" ]; then
    echo "❌ 错误: config/redis.conf 文件不存在"
    exit 1
fi

# 停止现有服务（如果存在）
echo "🛑 停止现有服务..."
docker-compose down 2>/dev/null || true

# 启动服务
echo "🔄 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

# 等待Redis完全启动
echo "⏳ 等待Redis完全启动..."
for i in {1..30}; do
    if docker-compose exec -T db redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis已启动"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Redis启动超时"
        exit 1
    fi
    sleep 1
done

# 等待API服务启动
echo "⏳ 等待API服务启动..."
for i in {1..60}; do
    if curl -s http://localhost:8848 > /dev/null 2>&1; then
        echo "✅ API服务已启动"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ API服务启动超时"
        exit 1
    fi
    sleep 1
done

echo ""
echo "🎉 Jump Jump 启动成功！"
echo ""
echo "📋 服务信息:"
echo "   管理后台: http://localhost:8848"
echo "   短链接服务: http://localhost:9848"
echo "   Redis: localhost:6379"
echo ""
echo "📝 下一步:"
echo "   1. 运行 ./create-admin.sh 创建管理员账户"
echo "   2. 访问 http://localhost:8848 登录管理后台"
echo ""
echo "🔧 管理命令:"
echo "   查看日志: docker-compose logs -f"
echo "   停止服务: docker-compose down"
echo "   重启服务: docker-compose restart"
echo ""
