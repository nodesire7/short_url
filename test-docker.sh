#!/bin/bash

# 测试Docker运行脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🐳 测试Docker运行${NC}"

# 生成API Token
API_TOKEN=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p -c 32)

echo -e "${YELLOW}生成的API Token: $API_TOKEN${NC}"

# 停止并删除现有容器
echo -e "${BLUE}清理现有容器...${NC}"
docker stop shortlink-test 2>/dev/null || true
docker rm shortlink-test 2>/dev/null || true

# 创建数据目录
mkdir -p ./test-data

# 运行容器
echo -e "${BLUE}启动容器...${NC}"
docker run -d \
  --name shortlink-test \
  -p 2282:2282 \
  -e API_TOKEN="$API_TOKEN" \
  -e BASE_URL="http://localhost:2282" \
  -v $(pwd)/test-data:/app/data \
  shortlink-api:latest

# 等待服务启动
echo -e "${BLUE}等待服务启动...${NC}"
sleep 10

# 检查容器状态
if docker ps | grep -q shortlink-test; then
    echo -e "${GREEN}✅ 容器启动成功${NC}"
    
    # 测试健康检查
    echo -e "${BLUE}测试健康检查...${NC}"
    if curl -f http://localhost:2282/health; then
        echo -e "${GREEN}✅ 健康检查通过${NC}"
        
        # 测试API
        echo -e "${BLUE}测试API...${NC}"
        RESPONSE=$(curl -s -X POST http://localhost:2282/api/create \
            -H "Authorization: $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"url": "https://www.google.com", "title": "Google"}')
        
        if echo "$RESPONSE" | grep -q "success"; then
            echo -e "${GREEN}✅ API测试成功${NC}"
            echo "响应: $RESPONSE"
        else
            echo -e "${RED}❌ API测试失败${NC}"
            echo "响应: $RESPONSE"
        fi
    else
        echo -e "${RED}❌ 健康检查失败${NC}"
    fi
    
    # 显示日志
    echo -e "${BLUE}容器日志:${NC}"
    docker logs shortlink-test --tail 20
    
else
    echo -e "${RED}❌ 容器启动失败${NC}"
    docker logs shortlink-test
fi

echo -e "${YELLOW}API Token: $API_TOKEN${NC}"
echo -e "${YELLOW}服务地址: http://localhost:2282${NC}"
echo -e "${YELLOW}停止容器: docker stop shortlink-test${NC}"
