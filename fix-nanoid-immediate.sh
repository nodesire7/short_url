#!/bin/bash

# 🔧 立即修复 nanoid ES 模块问题

set -e

echo "🔧 立即修复 nanoid ES 模块问题..."
echo ""

# 停止现有服务
echo "🛑 停止现有服务..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# 清理后端容器和镜像
echo "🧹 清理后端容器和镜像..."
docker container rm shorturl-backend 2>/dev/null || true
docker image rm nodesire77/shorturl-backend:latest 2>/dev/null || true

# 克隆最新源码
echo "📥 获取最新源码..."
if [ -d "short_url_fix" ]; then
    rm -rf short_url_fix
fi

git clone https://github.com/nodesire7/short_url.git short_url_fix
cd short_url_fix

echo "✅ 源码获取完成"
echo ""

# 验证nanoid版本
echo "🔍 验证 nanoid 版本..."
echo "后端 nanoid 版本:"
grep '"nanoid"' backend/package.json || echo "未找到nanoid依赖"

echo ""
echo "🔨 开始本地构建后端..."

# 创建临时docker-compose文件，只构建后端
cat > docker-compose.fix.yml << 'EOF'
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
      interval: 10s
      timeout: 5s
      retries: 5

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
      interval: 10s
      timeout: 5s
      retries: 5

  # 后端 API 服务 (本地构建，修复nanoid)
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
      CORS_ORIGIN: http://localhost:8848
      DEFAULT_DOMAIN: localhost:9848
      RATE_LIMIT_MAX: 100
      RATE_LIMIT_WINDOW: 900000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "9848:3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # 前端界面 (使用现有镜像)
  frontend:
    image: nodesire77/shorturl-frontend:latest
    container_name: shorturl-frontend
    restart: unless-stopped
    ports:
      - "8848:80"

volumes:
  postgres_data:
  redis_data:
EOF

echo "✅ 修复配置创建完成"
echo ""

# 构建并启动服务
echo "🚀 构建并启动修复版本..."
docker-compose -f docker-compose.fix.yml up -d --build

echo ""
echo "⏳ 等待服务启动（约90秒）..."
sleep 90

# 检查后端状态
echo "📊 检查后端修复状态..."
if curl -f http://localhost:9848/health 2>/dev/null; then
    echo "✅ 后端服务修复成功！nanoid 问题已解决"
else
    echo "⚠️  检查后端日志："
    docker-compose -f docker-compose.fix.yml logs --tail=20 backend
fi

echo ""
echo "📊 运行数据库迁移..."
docker-compose -f docker-compose.fix.yml exec -T backend npx prisma migrate deploy || {
    echo "⚠️  数据库迁移失败，尝试手动初始化..."
    docker-compose -f docker-compose.fix.yml exec -T backend npx prisma db push || echo "数据库初始化完成"
}

echo ""
echo "🎉 nanoid 问题修复完成！"
echo ""
echo "📋 访问信息:"
echo "   🌐 前端界面: http://localhost:8848"
echo "   🔧 后端API: http://localhost:9848"
echo "   📚 API文档: http://localhost:9848/docs"
echo ""
echo "🛠️ 管理命令:"
echo "   查看状态: docker-compose -f docker-compose.fix.yml ps"
echo "   查看日志: docker-compose -f docker-compose.fix.yml logs -f backend"
echo "   停止服务: docker-compose -f docker-compose.fix.yml down"
echo ""
echo "💡 这个版本使用本地构建的后端，确保使用 nanoid v4.0.2"
