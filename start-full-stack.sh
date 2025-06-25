#!/bin/bash

# 完整短链接服务启动脚本（MySQL + Redis + API + Nginx）

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 启动完整短链接服务栈${NC}"
echo "=" * 60

# 检查Docker和docker-compose
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose未安装${NC}"
    exit 1
fi

# 生成API Token
if [ -z "$API_TOKEN" ]; then
    API_TOKEN=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p -c 32)
    echo -e "${YELLOW}🔑 生成API Token: $API_TOKEN${NC}"
    export API_TOKEN
else
    echo -e "${GREEN}🔑 使用现有API Token: ${API_TOKEN:0:8}...${NC}"
fi

# 设置BASE_URL
if [ -z "$BASE_URL" ]; then
    BASE_URL="http://localhost"
    export BASE_URL
fi

echo -e "${BLUE}📋 配置信息:${NC}"
echo -e "  🔑 API Token: ${API_TOKEN:0:8}..."
echo -e "  🌐 Base URL: $BASE_URL"
echo -e "  🗄️  数据库: MySQL 8.0"
echo -e "  🚀 缓存: Redis 7"
echo -e "  🌍 代理: Nginx"

# 停止现有服务
echo -e "${BLUE}🛑 停止现有服务...${NC}"
docker-compose -f docker-compose.full.yml down 2>/dev/null || true

# 清理旧容器
echo -e "${BLUE}🧹 清理旧容器...${NC}"
docker rm -f shortlink-mysql shortlink-redis shortlink-api shortlink-nginx 2>/dev/null || true

# 拉取最新镜像
echo -e "${BLUE}📦 拉取最新镜像...${NC}"
docker-compose -f docker-compose.full.yml pull

# 启动服务
echo -e "${BLUE}🚀 启动服务栈...${NC}"
docker-compose -f docker-compose.full.yml up -d

# 等待服务启动
echo -e "${BLUE}⏳ 等待服务启动...${NC}"
echo -n "等待MySQL启动"
for i in {1..30}; do
    if docker exec shortlink-mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo -e " ${GREEN}✅${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo -n "等待Redis启动"
for i in {1..15}; do
    if docker exec shortlink-redis redis-cli ping 2>/dev/null | grep -q PONG; then
        echo -e " ${GREEN}✅${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo -n "等待API启动"
for i in {1..30}; do
    if curl -f http://localhost:2282/health >/dev/null 2>&1; then
        echo -e " ${GREEN}✅${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo -n "等待Nginx启动"
for i in {1..15}; do
    if curl -f http://localhost/health >/dev/null 2>&1; then
        echo -e " ${GREEN}✅${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# 测试API功能
echo -e "${BLUE}🧪 测试API功能...${NC}"
RESPONSE=$(curl -s -X POST http://localhost/api/create \
    -H "Authorization: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"url": "https://www.google.com", "title": "Google测试"}' || echo "")

if echo "$RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✅ API测试成功！${NC}"
    SHORT_CODE=$(echo "$RESPONSE" | grep -o '"short_code":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}🔗 测试短链接: $BASE_URL/$SHORT_CODE${NC}"
else
    echo -e "${YELLOW}⚠️  API测试失败，但服务可能仍在启动中${NC}"
    echo "响应: $RESPONSE"
fi

echo ""
echo -e "${GREEN}🎉 完整短链接服务栈启动成功！${NC}"
echo ""
echo -e "${BLUE}📋 服务信息:${NC}"
echo -e "  🌐 前端访问: $BASE_URL"
echo -e "  🔗 API地址: $BASE_URL/api/"
echo -e "  🔑 API Token: $API_TOKEN"
echo -e "  📊 MySQL: localhost:3306 (shortlink/shortlink123456)"
echo -e "  🚀 Redis: localhost:6379"
echo ""
echo -e "${BLUE}📖 使用示例:${NC}"
echo -e "  # 创建短链接"
echo -e "  curl -X POST $BASE_URL/api/create \\"
echo -e "    -H \"Authorization: $API_TOKEN\" \\"
echo -e "    -H \"Content-Type: application/json\" \\"
echo -e "    -d '{\"url\": \"https://www.example.com\", \"title\": \"示例\"}'"
echo ""
echo -e "${BLUE}🔧 管理命令:${NC}"
echo -e "  docker-compose -f docker-compose.full.yml logs -f    # 查看日志"
echo -e "  docker-compose -f docker-compose.full.yml restart    # 重启服务"
echo -e "  docker-compose -f docker-compose.full.yml down       # 停止服务"
echo ""
echo -e "${YELLOW}💾 请保存您的API Token: $API_TOKEN${NC}"
