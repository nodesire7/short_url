#!/bin/bash

# Jump Jump 修复和重启脚本
# 解决启动问题并确保服务正常运行

set -e

echo "🔧 修复并重启 Jump Jump 服务..."

# 停止现有服务
echo "🛑 停止现有服务..."
docker-compose -f ./docker-compose.yaml -p jumpjump down 2>/dev/null || true

# 清理可能的问题
echo "🧹 清理环境..."
docker system prune -f 2>/dev/null || true

# 创建必要的目录
echo "📁 创建必要目录..."
mkdir -p data/redis
mkdir -p logs/api
mkdir -p logs/landing
mkdir -p config

# 设置权限
chmod 755 data/redis logs/api logs/landing config

# 检查并修复Redis配置
if [ ! -f "config/redis.conf" ]; then
    echo "⚙️ 创建Redis配置文件..."
    cat > config/redis.conf << 'EOF'
# Redis配置 - Jump Jump
bind 0.0.0.0
port 6379
protected-mode no

# 持久化
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
save 900 1
save 300 10
save 60 10000

# 基本设置
dir /data
databases 16
timeout 0
tcp-keepalive 300
loglevel notice
EOF
fi

# 启动服务
echo "🚀 启动服务..."
docker-compose -f ./docker-compose.yaml -p jumpjump up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f ./docker-compose.yaml -p jumpjump ps

# 检查Redis连接
echo "🔄 检查Redis连接..."
for i in {1..30}; do
    if docker-compose -f ./docker-compose.yaml -p jumpjump exec -T db redis-cli ping 2>/dev/null | grep -q "PONG"; then
        echo "✅ Redis连接正常"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Redis连接失败"
        echo "📋 Redis日志:"
        docker-compose -f ./docker-compose.yaml -p jumpjump logs db
        exit 1
    fi
    sleep 1
done

# 检查API服务
echo "🔄 检查API服务..."
for i in {1..60}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8848 | grep -q "200\|404\|302"; then
        echo "✅ API服务响应正常"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ API服务无响应"
        echo "📋 API服务日志:"
        docker-compose -f ./docker-compose.yaml -p jumpjump logs apiserver
        exit 1
    fi
    sleep 1
done

# 检查Landing服务
echo "🔄 检查Landing服务..."
for i in {1..60}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9848 | grep -q "200\|404\|302"; then
        echo "✅ Landing服务响应正常"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ Landing服务无响应"
        echo "📋 Landing服务日志:"
        docker-compose -f ./docker-compose.yaml -p jumpjump logs landingserver
        exit 1
    fi
    sleep 1
done

echo ""
echo "🎉 服务启动成功！"
echo ""
echo "📋 服务信息:"
echo "   管理后台: http://localhost:8848"
echo "   短链接服务: http://localhost:9848"
echo "   Redis: localhost:6379"
echo ""
echo "📝 下一步:"
echo "   运行以下命令创建管理员用户:"
echo "   docker-compose -f ./docker-compose.yaml -p jumpjump exec apiserver ./createuser -username=admin -password=123456 -role=2"
echo ""
echo "🔧 查看日志:"
echo "   docker-compose -f ./docker-compose.yaml -p jumpjump logs -f"
echo ""
