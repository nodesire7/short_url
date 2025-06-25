#!/bin/bash

# Docker容器启动脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting Short Link API...${NC}"

# 检查API_TOKEN
if [ -z "$API_TOKEN" ]; then
    echo -e "${RED}❌ API_TOKEN environment variable is required${NC}"
    exit 1
fi

# 显示配置信息
echo -e "${BLUE}📋 Configuration:${NC}"
echo -e "  API_TOKEN: ${API_TOKEN:0:8}..."
echo -e "  BASE_URL: ${BASE_URL:-http://localhost:2282}"
echo -e "  DATABASE_PATH: ${DATABASE_PATH:-/app/data/shortlinks.db}"
echo -e "  LOG_LEVEL: ${LOG_LEVEL:-INFO}"

# 确保数据目录存在并有正确权限
DATA_DIR="/app/data"
LOGS_DIR="/app/logs"

echo -e "${BLUE}📁 Setting up directories...${NC}"

# 创建目录
mkdir -p "$DATA_DIR" "$LOGS_DIR"

# 尝试设置权限
if [ -w "$DATA_DIR" ]; then
    echo -e "${GREEN}✅ Data directory is writable: $DATA_DIR${NC}"
else
    echo -e "${YELLOW}⚠️  Data directory not writable, trying to fix permissions...${NC}"

    # 尝试多种权限修复方法
    sudo chown -R $(id -u):$(id -g) "$DATA_DIR" 2>/dev/null || true
    sudo chmod 777 "$DATA_DIR" 2>/dev/null || true
    chmod 777 "$DATA_DIR" 2>/dev/null || true

    # 再次检查
    if [ -w "$DATA_DIR" ]; then
        echo -e "${GREEN}✅ Permissions fixed for: $DATA_DIR${NC}"
    else
        echo -e "${YELLOW}⚠️  Cannot fix permissions, application will use alternative paths${NC}"
    fi
fi

if [ -w "$LOGS_DIR" ]; then
    echo -e "${GREEN}✅ Logs directory is writable: $LOGS_DIR${NC}"
else
    echo -e "${YELLOW}⚠️  Logs directory not writable, trying to fix permissions...${NC}"
    chmod 777 "$LOGS_DIR" 2>/dev/null || echo -e "${YELLOW}⚠️  Cannot change permissions, will try alternative paths${NC}"
fi

# 测试数据库文件创建
DB_PATH="${DATABASE_PATH:-/app/data/shortlinks.db}"
DB_DIR=$(dirname "$DB_PATH")

echo -e "${BLUE}🗄️  Testing database access...${NC}"

if [ -w "$DB_DIR" ]; then
    echo -e "${GREEN}✅ Database directory is writable: $DB_DIR${NC}"
    # 测试创建数据库文件
    if python3 -c "
import sqlite3
import os
try:
    conn = sqlite3.connect('$DB_PATH')
    conn.execute('SELECT 1')
    conn.close()
    print('Database test successful')
except Exception as e:
    print(f'Database test failed: {e}')
    exit(1)
"; then
        echo -e "${GREEN}✅ Database test passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Database test failed, will use fallback${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Database directory not writable: $DB_DIR${NC}"
fi

# 显示当前用户信息
echo -e "${BLUE}👤 Running as:${NC}"
echo -e "  User: $(whoami) ($(id -u):$(id -g))"
echo -e "  Groups: $(groups)"

# 显示目录权限
echo -e "${BLUE}📂 Directory permissions:${NC}"
ls -la /app/ | head -5

# 修复权限
echo -e "${BLUE}🔧 Fixing permissions...${NC}"
chown -R appuser:appuser /app/data /app/logs 2>/dev/null || true
chmod 755 /app/data /app/logs 2>/dev/null || true

# 启动应用
echo -e "${GREEN}🎉 Starting application...${NC}"

# 根据参数决定启动方式
if [ "$1" = "dev" ]; then
    echo -e "${YELLOW}🔧 Development mode${NC}"
    exec su-exec appuser python3 app.py 2>/dev/null || exec python3 app.py
else
    echo -e "${BLUE}🚀 Production mode with Gunicorn${NC}"
    exec su-exec appuser gunicorn --config gunicorn.conf.py app:app 2>/dev/null || exec gunicorn --config gunicorn.conf.py app:app
fi
