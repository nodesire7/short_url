#!/bin/bash

# 创建Jump Jump管理员用户脚本

set -e

echo "👤 创建Jump Jump管理员用户"
echo ""

# 检查服务是否运行
if ! docker-compose -f ./docker-compose.yaml -p jumpjump ps | grep -q "jumpjump-api.*Up"; then
    echo "❌ 错误: API服务未运行"
    echo "请先运行: ./fix-and-restart.sh"
    exit 1
fi

# 获取用户输入
read -p "请输入管理员用户名 (默认: admin): " username
username=${username:-admin}

# 获取密码（隐藏输入）
echo -n "请输入密码 (默认: 123456): "
read -s password
echo ""
password=${password:-123456}

echo ""
echo "🔄 正在创建管理员用户..."

# 创建管理员用户
if docker-compose -f ./docker-compose.yaml -p jumpjump exec -T apiserver ./createuser -username="$username" -password="$password" -role=2; then
    echo ""
    echo "✅ 管理员用户创建成功！"
    echo ""
    echo "📋 登录信息:"
    echo "   用户名: $username"
    echo "   密码: $password"
    echo "   角色: 管理员"
    echo ""
    echo "🌐 访问地址:"
    echo "   管理后台: http://localhost:8848"
    echo ""
    echo "💡 提示:"
    echo "   - 请妥善保管登录信息"
    echo "   - 建议在管理后台设置短链接域名"
    echo "   - 可以创建更多普通用户账户"
    echo ""
else
    echo ""
    echo "❌ 管理员用户创建失败"
    echo "📋 检查服务状态:"
    docker-compose -f ./docker-compose.yaml -p jumpjump ps
    echo ""
    echo "📋 API服务日志:"
    docker-compose -f ./docker-compose.yaml -p jumpjump logs --tail=20 apiserver
    exit 1
fi
