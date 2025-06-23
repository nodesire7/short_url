#!/bin/bash

# 🔍 后端容器错误诊断脚本

set -e

echo "🔍 开始诊断后端容器问题..."
echo ""

# 检查容器状态
echo "📊 检查容器状态..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "📋 查看后端容器日志..."
docker-compose -f docker-compose.prod.yml logs --tail=50 backend

echo ""
echo "🔍 检查后端容器详细信息..."
docker inspect shorturl-backend 2>/dev/null | grep -A 10 -B 5 "Health\|State" || echo "容器不存在或已停止"

echo ""
echo "📊 检查数据库连接..."
echo "PostgreSQL状态:"
docker-compose -f docker-compose.prod.yml exec postgres pg_isready -U shorturl -d shorturl || echo "数据库连接失败"

echo ""
echo "📊 检查Redis连接..."
echo "Redis状态:"
docker-compose -f docker-compose.prod.yml exec redis redis-cli -a redis_secure_2024 ping || echo "Redis连接失败"

echo ""
echo "🔧 尝试手动启动后端容器..."
docker-compose -f docker-compose.prod.yml up backend --no-deps -d

echo ""
echo "⏳ 等待30秒后再次检查..."
sleep 30

echo ""
echo "📋 最新后端日志:"
docker-compose -f docker-compose.prod.yml logs --tail=20 backend

echo ""
echo "🔍 检查健康检查端点..."
if curl -f http://localhost:9848/health 2>/dev/null; then
    echo "✅ 后端健康检查通过"
else
    echo "❌ 后端健康检查失败"
    echo ""
    echo "🔧 尝试直接访问容器内部..."
    docker-compose -f docker-compose.prod.yml exec backend curl -f http://localhost:3000/health 2>/dev/null || echo "容器内部健康检查也失败"
fi

echo ""
echo "📊 网络连接测试..."
echo "测试容器间网络连接:"
docker-compose -f docker-compose.prod.yml exec backend ping -c 3 postgres || echo "无法连接到postgres"
docker-compose -f docker-compose.prod.yml exec backend ping -c 3 redis || echo "无法连接到redis"

echo ""
echo "🔍 诊断完成！"
echo ""
echo "💡 常见解决方案:"
echo "1. 如果是数据库连接问题，检查DATABASE_URL配置"
echo "2. 如果是Redis连接问题，检查REDIS_URL配置"
echo "3. 如果是健康检查超时，增加健康检查等待时间"
echo "4. 如果是依赖问题，重新构建镜像"
echo ""
echo "🛠️ 手动修复命令:"
echo "   重新构建: docker-compose -f docker-compose.prod.yml build --no-cache backend"
echo "   重新启动: docker-compose -f docker-compose.prod.yml restart backend"
echo "   查看日志: docker-compose -f docker-compose.prod.yml logs -f backend"
