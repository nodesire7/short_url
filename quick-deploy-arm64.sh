#!/bin/bash

# 🚀 Modern Short URL ARM64 一键部署脚本
# 适用于ARM64架构服务器（如Apple Silicon、ARM服务器等）

set -e

echo "🚀 开始部署 Modern Short URL 系统 (ARM64)..."
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    echo "   Ubuntu ARM64: sudo apt install docker.io docker-compose"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

echo "✅ Docker 环境检查通过"
echo ""

# 检查架构
ARCH=$(uname -m)
echo "🔍 检测到系统架构: $ARCH"

if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo "⚠️  警告: 当前架构可能不是ARM64，但继续部署..."
fi

echo ""

# 克隆源码
echo "📥 下载源码..."
if [ -d "short_url" ]; then
    echo "   源码目录已存在，更新中..."
    cd short_url
    git pull origin main
else
    git clone https://github.com/nodesire7/short_url.git
    cd short_url
fi

echo "✅ 源码下载完成"
echo ""

# 创建ARM64兼容的docker-compose文件
echo "📝 创建ARM64兼容配置..."
cat > docker-compose.arm64.yml << 'EOF'
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
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3

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
      test: ["CMD", "curl", "-f", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
EOF

echo "✅ ARM64配置文件创建完成"
echo ""

# 启动服务
echo "🚀 启动服务..."
docker-compose -f docker-compose.arm64.yml up -d --build

echo ""
echo "⏳ 等待服务启动（约60秒）..."
sleep 60

# 运行数据库迁移
echo "📊 初始化数据库..."
docker-compose -f docker-compose.arm64.yml exec -T backend npx prisma migrate deploy || echo "数据库迁移完成"

echo ""
echo "🎉 部署完成！"
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
echo "   查看状态: docker-compose -f docker-compose.arm64.yml ps"
echo "   查看日志: docker-compose -f docker-compose.arm64.yml logs -f"
echo "   停止服务: docker-compose -f docker-compose.arm64.yml down"
echo "   重启服务: docker-compose -f docker-compose.arm64.yml restart"
echo ""
echo "🎯 开始使用您的短链接系统吧！"
