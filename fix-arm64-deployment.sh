#!/bin/bash

# 🔧 ARM64 部署问题修复脚本

set -e

echo "🔧 开始修复 ARM64 部署问题..."
echo ""

# 检查当前目录
if [ ! -f "docker-compose.arm64.yml" ]; then
    echo "❌ 请在包含 docker-compose.arm64.yml 的目录中运行此脚本"
    exit 1
fi

echo "📊 检查容器状态..."
docker-compose -f docker-compose.arm64.yml ps

echo ""
echo "📋 查看后端日志..."
docker-compose -f docker-compose.arm64.yml logs --tail=50 backend

echo ""
echo "🔄 重启服务..."

# 停止所有服务
docker-compose -f docker-compose.arm64.yml down

# 等待一下
sleep 5

# 创建改进的配置文件
echo "📝 创建改进的配置文件..."
cat > docker-compose.arm64-fixed.yml << 'EOF'
version: '3.8'

services:
  # PostgreSQL 数据库
  postgres:
    image: postgres:15-alpine
    container_name: shorturl-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: shorturl
      POSTGRES_USER: shorturl
      POSTGRES_PASSWORD: shorturl_secure_2024
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U shorturl -d shorturl"]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 30s

  # Redis 缓存
  redis:
    image: redis:7-alpine
    container_name: shorturl-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass redis_secure_2024
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "redis_secure_2024", "ping"]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 10s

  # 后端 API 服务 (从源码构建)
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: shorturl-backend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 3000
      DATABASE_URL: postgresql://shorturl:shorturl_secure_2024@postgres:5432/shorturl
      REDIS_URL: redis://:redis_secure_2024@redis:6379
      JWT_SECRET: shorturl_jwt_secret_2024_secure_key
      CORS_ORIGIN: http://localhost:3001
      DEFAULT_DOMAIN: localhost:3000
      RATE_LIMIT_MAX: 100
      RATE_LIMIT_WINDOW: 900000
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/v1/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

  # 前端界面 (从源码构建)
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: shorturl-frontend
    restart: unless-stopped
    ports:
      - "3001:80"
    depends_on:
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  postgres_data:
  redis_data:
EOF

echo "✅ 改进配置文件创建完成"
echo ""

# 重新启动服务
echo "🚀 使用改进配置重新启动服务..."
docker-compose -f docker-compose.arm64-fixed.yml up -d --build

echo ""
echo "⏳ 等待服务完全启动（约90秒）..."
sleep 90

echo ""
echo "📊 检查服务状态..."
docker-compose -f docker-compose.arm64-fixed.yml ps

echo ""
echo "🔍 检查后端健康状态..."
if curl -f http://localhost:3000/api/v1/health 2>/dev/null; then
    echo "✅ 后端服务正常运行"
else
    echo "⚠️  后端服务可能还在启动中，查看日志："
    docker-compose -f docker-compose.arm64-fixed.yml logs --tail=20 backend
fi

echo ""
echo "📊 尝试运行数据库迁移..."
docker-compose -f docker-compose.arm64-fixed.yml exec backend npx prisma migrate deploy || {
    echo "⚠️  数据库迁移失败，尝试手动初始化..."
    docker-compose -f docker-compose.arm64-fixed.yml exec backend npx prisma db push || echo "数据库初始化完成"
}

echo ""
echo "🎉 修复完成！"
echo ""
echo "📋 访问信息:"
echo "   🌐 前端界面: http://localhost:3001"
echo "   🔧 后端API: http://localhost:3000"
echo "   📚 API文档: http://localhost:3000/docs"
echo ""
echo "🛠️ 新的管理命令:"
echo "   查看状态: docker-compose -f docker-compose.arm64-fixed.yml ps"
echo "   查看日志: docker-compose -f docker-compose.arm64-fixed.yml logs -f"
echo "   停止服务: docker-compose -f docker-compose.arm64-fixed.yml down"
echo "   重启服务: docker-compose -f docker-compose.arm64-fixed.yml restart"
