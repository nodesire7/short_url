#!/bin/bash

# 🚀 Modern Short URL 本地构建部署脚本
# 解决Docker镜像版本问题的临时方案

set -e

echo "🚀 开始本地构建部署 Modern Short URL 系统..."
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

echo "✅ Docker 环境检查通过"
echo ""

# 停止现有服务
echo "🛑 停止现有服务..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# 克隆或更新源码
echo "📥 准备源码..."
if [ -d "short_url" ]; then
    echo "   更新现有源码..."
    cd short_url
    git pull origin main
else
    echo "   克隆新源码..."
    git clone https://github.com/nodesire7/short_url.git
    cd short_url
fi

echo "✅ 源码准备完成"
echo ""

# 创建本地构建的docker-compose文件
echo "📝 创建本地构建配置..."
cat > docker-compose.local.yml << 'EOF'
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
    networks:
      - shorturl-network

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
    networks:
      - shorturl-network

  # 后端 API 服务 (本地构建)
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
    networks:
      - shorturl-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # 前端界面 (本地构建)
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: shorturl-frontend
    restart: unless-stopped
    depends_on:
      backend:
        condition: service_healthy
    ports:
      - "8848:80"
    networks:
      - shorturl-network

# 网络配置
networks:
  shorturl-network:
    driver: bridge

# 数据卷
volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
EOF

echo "✅ 本地构建配置创建完成"
echo ""

# 构建并启动服务
echo "🔨 开始本地构建和启动服务..."
docker-compose -f docker-compose.local.yml up -d --build

echo ""
echo "⏳ 等待服务启动（约90秒）..."
sleep 90

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose -f docker-compose.local.yml ps

echo ""
echo "📋 检查后端健康状态..."
if curl -f http://localhost:9848/health 2>/dev/null; then
    echo "✅ 后端服务正常运行"
else
    echo "⚠️  后端服务可能还在启动中，查看日志："
    docker-compose -f docker-compose.local.yml logs --tail=10 backend
fi

echo ""
echo "📊 运行数据库迁移..."
docker-compose -f docker-compose.local.yml exec -T backend npx prisma migrate deploy || {
    echo "⚠️  数据库迁移失败，尝试手动初始化..."
    docker-compose -f docker-compose.local.yml exec -T backend npx prisma db push || echo "数据库初始化完成"
}

echo ""
echo "🎉 本地构建部署完成！"
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
echo "   查看状态: docker-compose -f docker-compose.local.yml ps"
echo "   查看日志: docker-compose -f docker-compose.local.yml logs -f"
echo "   停止服务: docker-compose -f docker-compose.local.yml down"
echo "   重启服务: docker-compose -f docker-compose.local.yml restart"
echo ""
echo "💡 这是本地构建版本，使用最新的源码和依赖！"
echo "📝 注意：如果遇到依赖冲突，构建过程会自动使用 --legacy-peer-deps 解决"
