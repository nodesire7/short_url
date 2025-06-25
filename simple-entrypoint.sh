#!/bin/bash

# 简单的Docker启动脚本

set -e

echo "🚀 Starting Short Link API..."

# 检查API_TOKEN
if [ -z "$API_TOKEN" ]; then
    echo "❌ API_TOKEN environment variable is required"
    exit 1
fi

echo "📋 Configuration:"
echo "  API_TOKEN: ${API_TOKEN:0:8}..."
echo "  BASE_URL: ${BASE_URL:-http://localhost:2282}"

# 创建数据目录并设置权限
mkdir -p /app/data /app/logs
chmod 777 /app/data /app/logs 2>/dev/null || true

# 显示目录权限
echo "📂 Directory permissions:"
ls -la /app/data /app/logs

# 启动应用
echo "🎉 Starting application..."
exec gunicorn --config gunicorn.conf.py app:app
