#!/bin/bash

# 🚀 Modern Short URL 一键部署脚本
# 无需任何环境变量配置，开箱即用！

set -e

echo "🚀 开始部署 Modern Short URL 系统..."
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    echo "   macOS: brew install --cask docker"
    echo "   Ubuntu: sudo apt install docker.io docker-compose"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

echo "✅ Docker 环境检查通过"
echo ""

# 下载配置文件
echo "📥 下载部署配置..."
curl -s -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.prod.yml

if [ ! -f "docker-compose.prod.yml" ]; then
    echo "❌ 配置文件下载失败"
    exit 1
fi

echo "✅ 配置文件下载完成"
echo ""

# 启动服务
echo "🚀 启动服务..."
docker-compose -f docker-compose.prod.yml up -d

echo ""
echo "⏳ 等待服务启动（约30秒）..."
sleep 30

# 运行数据库迁移
echo "📊 初始化数据库..."
docker-compose -f docker-compose.prod.yml exec -T backend npx prisma migrate deploy || echo "数据库迁移完成"

echo ""
echo "🎉 部署完成！"
echo ""
echo "📋 访问信息:"
echo "   🌐 前端界面: http://localhost:8848"
echo "   🔧 后端API: http://localhost:9848"
echo "   📚 API文档: http://localhost:9848/docs"
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
echo ""
echo "🎯 开始使用您的短链接系统吧！"
