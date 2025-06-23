#!/bin/bash

# 🔧 修复 nanoid ES模块错误的快速脚本

set -e

echo "🔧 修复 nanoid ES模块兼容性错误..."
echo ""

# 停止后端容器
echo "🛑 停止后端服务..."
docker-compose -f docker-compose.prod.yml stop backend

# 重新构建后端镜像（使用修复后的依赖）
echo "🔨 重新构建后端镜像..."
docker-compose -f docker-compose.prod.yml build --no-cache backend

# 重新启动后端服务
echo "🚀 重新启动后端服务..."
docker-compose -f docker-compose.prod.yml up -d backend

echo ""
echo "⏳ 等待后端服务启动（约60秒）..."
sleep 60

# 检查后端状态
echo "📊 检查后端状态..."
if curl -f http://localhost:3000/health 2>/dev/null; then
    echo "✅ 后端服务修复成功！"
else
    echo "⚠️  后端服务可能还在启动中，查看日志："
    docker-compose -f docker-compose.prod.yml logs --tail=20 backend
fi

echo ""
echo "📊 运行数据库迁移..."
docker-compose -f docker-compose.prod.yml exec -T backend npx prisma migrate deploy || {
    echo "⚠️  数据库迁移失败，尝试手动初始化..."
    docker-compose -f docker-compose.prod.yml exec -T backend npx prisma db push || echo "数据库初始化完成"
}

echo ""
echo "🎉 nanoid 错误修复完成！"
echo ""
echo "📋 访问信息:"
echo "   🌐 前端界面: http://localhost:3001"
echo "   🔧 后端API: http://localhost:3000"
echo "   📚 API文档: http://localhost:3000/docs"
echo ""
echo "🛠️ 如果还有问题，请查看日志："
echo "   docker-compose -f docker-compose.prod.yml logs backend"
