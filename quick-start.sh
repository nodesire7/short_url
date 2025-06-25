#!/bin/bash

# 短链接API快速启动脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 短链接API快速启动${NC}"
echo "=" * 50

# 生成API Token
if [ -z "$API_TOKEN" ]; then
    API_TOKEN=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p -c 32)
    echo -e "${YELLOW}🔑 生成API Token: $API_TOKEN${NC}"
else
    echo -e "${GREEN}🔑 使用现有API Token: ${API_TOKEN:0:8}...${NC}"
fi

# 创建数据目录
echo -e "${BLUE}📁 创建数据目录...${NC}"
mkdir -p ./shortlink-data ./shortlink-logs
chmod 777 ./shortlink-data ./shortlink-logs 2>/dev/null || true

# 停止现有容器
echo -e "${BLUE}🛑 停止现有容器...${NC}"
docker stop shortlink-api 2>/dev/null || true
docker rm shortlink-api 2>/dev/null || true

# 拉取最新镜像
echo -e "${BLUE}📦 拉取最新镜像...${NC}"
docker pull nodesire77/shorturl_api:latest

# 启动容器
echo -e "${BLUE}🚀 启动容器...${NC}"
docker run -d \
  --name shortlink-api \
  --restart unless-stopped \
  -p 2282:2282 \
  -e API_TOKEN="$API_TOKEN" \
  -e BASE_URL="http://localhost:2282" \
  -v $(pwd)/shortlink-data:/app/data \
  -v $(pwd)/shortlink-logs:/app/logs \
  nodesire77/shorturl_api:latest

# 等待服务启动
echo -e "${BLUE}⏳ 等待服务启动...${NC}"
sleep 10

# 检查容器状态
if docker ps | grep -q shortlink-api; then
    echo -e "${GREEN}✅ 容器启动成功！${NC}"
    
    # 等待健康检查
    echo -e "${BLUE}🔍 等待健康检查...${NC}"
    for i in {1..30}; do
        if curl -f http://localhost:2282/health >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 健康检查通过！${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
    
    # 测试API
    echo -e "${BLUE}🧪 测试API功能...${NC}"
    RESPONSE=$(curl -s -X POST http://localhost:2282/api/create \
        -H "Authorization: $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"url": "https://www.google.com", "title": "Google测试"}' || echo "")
    
    if echo "$RESPONSE" | grep -q "success"; then
        echo -e "${GREEN}✅ API测试成功！${NC}"
        SHORT_CODE=$(echo "$RESPONSE" | grep -o '"short_code":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}🔗 测试短链接: http://localhost:2282/$SHORT_CODE${NC}"
    else
        echo -e "${YELLOW}⚠️  API测试失败，但服务可能仍在启动中${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 短链接API启动成功！${NC}"
    echo ""
    echo -e "${BLUE}📋 服务信息:${NC}"
    echo -e "  🌐 服务地址: http://localhost:2282"
    echo -e "  🔑 API Token: $API_TOKEN"
    echo -e "  📚 API文档: http://localhost:2282"
    echo -e "  ❤️  健康检查: http://localhost:2282/health"
    echo ""
    echo -e "${BLUE}📖 使用示例:${NC}"
    echo -e "  # 创建短链接"
    echo -e "  curl -X POST http://localhost:2282/api/create \\"
    echo -e "    -H \"Authorization: $API_TOKEN\" \\"
    echo -e "    -H \"Content-Type: application/json\" \\"
    echo -e "    -d '{\"url\": \"https://www.example.com\", \"title\": \"示例\"}'"
    echo ""
    echo -e "${BLUE}🔧 管理命令:${NC}"
    echo -e "  docker logs shortlink-api -f     # 查看日志"
    echo -e "  docker restart shortlink-api     # 重启服务"
    echo -e "  docker stop shortlink-api        # 停止服务"
    echo ""
    echo -e "${YELLOW}💾 请保存您的API Token: $API_TOKEN${NC}"
    
else
    echo -e "${RED}❌ 容器启动失败${NC}"
    echo -e "${BLUE}📋 容器日志:${NC}"
    docker logs shortlink-api
    exit 1
fi
