#!/bin/bash

# 容器内启动脚本

set -e

echo "🚀 Starting All-in-One Short Link Service..."

# 检查环境变量
if [ -z "$API_TOKEN" ]; then
    echo "❌ API_TOKEN environment variable is required"
    exit 1
fi

echo "📋 Configuration:"
echo "  API_TOKEN: ${API_TOKEN:0:8}..."
echo "  BASE_URL: ${BASE_URL:-http://localhost:2282}"

# 初始化MySQL数据目录（如果需要）
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "🗄️ Initializing MySQL..."
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

# 启动MySQL
echo "🗄️ Starting MySQL..."
service mysql start

# 等待MySQL启动
echo "⏳ Waiting for MySQL..."
for i in {1..30}; do
    if mysqladmin ping -h localhost --silent; then
        echo "✅ MySQL is ready"
        break
    fi
    sleep 1
done

# 创建数据库和用户（如果不存在）
echo "🔧 Setting up database..."
mysql -e "CREATE DATABASE IF NOT EXISTS shortlink;" 2>/dev/null || true
mysql -e "GRANT ALL PRIVILEGES ON shortlink.* TO 'shortlink'@'localhost';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

# 启动Redis
echo "🚀 Starting Redis..."
service redis-server start

# 等待Redis启动
echo "⏳ Waiting for Redis..."
for i in {1..15}; do
    if redis-cli ping | grep -q PONG; then
        echo "✅ Redis is ready"
        break
    fi
    sleep 1
done

# 设置环境变量 - 强制使用MySQL
export DB_TYPE=mysql
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=shortlink
export MYSQL_PASSWORD=shortlink123456
export MYSQL_DATABASE=shortlink
export REDIS_HOST=localhost
export REDIS_PORT=6379

# 确保不使用SQLite
unset DATABASE_PATH

# 启动API服务
echo "🎉 Starting API service..."
cd /app

# 初始化数据库表
python3 -c "
from app import init_db
try:
    init_db()
    print('✅ Database initialized successfully')
except Exception as e:
    print(f'⚠️ Database initialization: {e}')
"

# 启动Gunicorn
exec gunicorn --config gunicorn.conf.py app:app
