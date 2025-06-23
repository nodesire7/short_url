#!/bin/bash

# 🚀 Modern Short URL ARM64 简化部署脚本
# 解决构建问题的简化版本

set -e

echo "🚀 开始简化部署 Modern Short URL 系统 (ARM64)..."
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

# 停止可能存在的服务
echo "🛑 停止现有服务..."
docker-compose -f docker-compose.arm64.yml down 2>/dev/null || true
docker-compose -f docker-compose.arm64-fixed.yml down 2>/dev/null || true

# 清理可能的问题容器
echo "🧹 清理问题容器..."
docker container prune -f
docker image prune -f

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

# 创建超简化的docker-compose文件
echo "📝 创建简化配置..."
cat > docker-compose.simple.yml << 'EOF'
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
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    command: >
      postgres
      -c shared_preload_libraries=''
      -c max_connections=200
      -c shared_buffers=128MB

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

  # 后端 API 服务 (使用Node.js基础镜像)
  backend:
    image: node:18-alpine
    container_name: shorturl-backend
    restart: unless-stopped
    working_dir: /app
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
    volumes:
      - ./backend:/app
      - backend_node_modules:/app/node_modules
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    command: >
      sh -c "
        echo '安装依赖...' &&
        npm install &&
        echo '生成Prisma客户端...' &&
        npx prisma generate &&
        echo '等待数据库...' &&
        sleep 30 &&
        echo '运行数据库迁移...' &&
        npx prisma migrate deploy &&
        echo '启动应用...' &&
        npm start
      "

  # 前端界面 (使用Nginx基础镜像)
  frontend:
    image: nginx:alpine
    container_name: shorturl-frontend
    restart: unless-stopped
    ports:
      - "3001:80"
    volumes:
      - ./frontend/dist:/usr/share/nginx/html:ro
      - ./frontend/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - backend

volumes:
  postgres_data:
  redis_data:
  backend_node_modules:
EOF

echo "✅ 简化配置创建完成"
echo ""

# 检查前端构建目录
echo "🔨 准备前端文件..."
if [ ! -d "frontend/dist" ]; then
    echo "   创建前端构建目录..."
    mkdir -p frontend/dist
    echo '<h1>Frontend Building...</h1><p>Please wait while the frontend is being built.</p>' > frontend/dist/index.html
fi

# 检查nginx配置
if [ ! -f "frontend/nginx.conf" ]; then
    echo "   创建Nginx配置..."
    cat > frontend/nginx.conf << 'NGINX_EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files $uri $uri/ /index.html;
        }
        
        location /api/ {
            proxy_pass http://backend:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
NGINX_EOF
fi

echo "✅ 前端文件准备完成"
echo ""

# 启动服务
echo "🚀 启动简化服务..."
docker-compose -f docker-compose.simple.yml up -d

echo ""
echo "⏳ 等待服务启动（约120秒）..."
echo "   数据库初始化需要时间，请耐心等待..."

# 显示启动进度
for i in {1..12}; do
    sleep 10
    echo "   等待中... ($((i*10))/120秒)"
    
    # 检查后端日志
    if [ $i -eq 6 ]; then
        echo ""
        echo "📋 检查后端启动状态..."
        docker-compose -f docker-compose.simple.yml logs --tail=10 backend
        echo ""
    fi
done

echo ""
echo "📊 检查最终状态..."
docker-compose -f docker-compose.simple.yml ps

echo ""
echo "📋 后端日志（最后20行）:"
docker-compose -f docker-compose.simple.yml logs --tail=20 backend

echo ""
echo "🎉 简化部署完成！"
echo ""
echo "📋 访问信息:"
echo "   🌐 前端界面: http://localhost:3001"
echo "   🔧 后端API: http://localhost:3000"
echo "   📚 API文档: http://localhost:3000/docs"
echo ""
echo "🛠️ 管理命令:"
echo "   查看状态: docker-compose -f docker-compose.simple.yml ps"
echo "   查看日志: docker-compose -f docker-compose.simple.yml logs -f"
echo "   停止服务: docker-compose -f docker-compose.simple.yml down"
echo "   重启服务: docker-compose -f docker-compose.simple.yml restart"
echo ""
echo "💡 如果后端还在启动中，请等待几分钟后访问"
