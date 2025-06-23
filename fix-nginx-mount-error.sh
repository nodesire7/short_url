#!/bin/bash

# 🔧 修复 Nginx 挂载错误的快速脚本

set -e

echo "🔧 修复 Nginx 挂载错误..."
echo ""

# 停止所有相关容器
echo "🛑 停止现有服务..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# 清理问题容器
echo "🧹 清理问题容器..."
docker container prune -f

# 下载修复后的配置文件
echo "📥 下载修复后的配置文件..."
curl -s -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.prod.yml

# 重新启动服务
echo "🚀 重新启动服务..."
docker-compose -f docker-compose.prod.yml up -d

echo ""
echo "⏳ 等待服务启动（约30秒）..."
sleep 30

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "📋 检查后端健康状态..."
if curl -f http://localhost:3000/health 2>/dev/null; then
    echo "✅ 后端服务正常运行"
else
    echo "⚠️  后端服务可能还在启动中"
    echo "📋 后端日志："
    docker-compose -f docker-compose.prod.yml logs --tail=10 backend
fi

echo ""
echo "📋 检查前端状态..."
if curl -f http://localhost:3001 2>/dev/null; then
    echo "✅ 前端服务正常运行"
else
    echo "⚠️  前端服务可能还在启动中"
    echo "📋 前端日志："
    docker-compose -f docker-compose.prod.yml logs --tail=10 frontend
fi

echo ""
echo "📊 运行数据库迁移..."
docker-compose -f docker-compose.prod.yml exec -T backend npx prisma migrate deploy || {
    echo "⚠️  数据库迁移失败，尝试手动初始化..."
    docker-compose -f docker-compose.prod.yml exec -T backend npx prisma db push || echo "数据库初始化完成"
}

echo ""
echo "🎉 修复完成！"
echo ""
echo "📋 访问信息:"
echo "   🌐 前端界面: http://localhost:3001"
echo "   🔧 后端API: http://localhost:3000"
echo "   📚 API文档: http://localhost:3000/docs"
echo ""
echo "🔑 默认账户:"
echo "   👤 管理员: admin@shortlink.com / admin123456"
echo "   👤 测试用户: test@shortlink.com / test123456"
echo ""
echo "🛠️ 管理命令:"
echo "   查看状态: docker-compose -f docker-compose.prod.yml ps"
echo "   查看日志: docker-compose -f docker-compose.prod.yml logs -f"
echo "   停止服务: docker-compose -f docker-compose.prod.yml down"
echo "   重启服务: docker-compose -f docker-compose.prod.yml restart"
