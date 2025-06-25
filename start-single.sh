#!/bin/bash

# 一键启动单容器短链接服务

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 一键启动单容器短链接服务${NC}"
echo "包含: MySQL + Redis + API 全部在一个容器中"

# 生成API Token
API_TOKEN=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p -c 32)
export API_TOKEN

# 设置BASE_URL
if [ -z "$BASE_URL" ]; then
    echo -e "${YELLOW}🌐 请输入您的域名 (例如: https://s.gbtgame.me):${NC}"
    read -p "BASE_URL: " BASE_URL
    if [ -z "$BASE_URL" ]; then
        BASE_URL="http://localhost:2282"
        echo -e "${YELLOW}⚠️  使用默认地址: $BASE_URL${NC}"
    fi
    export BASE_URL
fi

echo -e "${YELLOW}🔑 API Token: $API_TOKEN${NC}"
echo -e "${YELLOW}🌐 Base URL: $BASE_URL${NC}"

# 停止现有服务
echo -e "${BLUE}🛑 停止现有服务...${NC}"
docker-compose -f docker-compose.single.yml down 2>/dev/null || true

# 启动服务
echo -e "${BLUE}🚀 启动单容器服务...${NC}"
docker-compose -f docker-compose.single.yml up -d

# 等待服务启动
echo -e "${BLUE}⏳ 等待服务启动（可能需要1-2分钟）...${NC}"
sleep 60

# 检查服务状态
echo -e "${BLUE}🔍 检查服务状态...${NC}"
if docker ps | grep -q shortlink-single; then
    echo -e "${GREEN}✅ 容器启动成功！${NC}"
    
    # 测试健康检查
    echo -e "${BLUE}🔍 等待服务就绪...${NC}"
    for i in {1..30}; do
        if curl -f http://localhost:2282/health >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 健康检查通过！${NC}"
            
            # 测试API
            echo -e "${BLUE}🧪 测试API...${NC}"
            RESPONSE=$(curl -s -X POST http://localhost:2282/api/create \
                -H "Authorization: $API_TOKEN" \
                -H "Content-Type: application/json" \
                -d '{"url": "https://www.google.com", "title": "Google测试"}' || echo "")
            
            if echo "$RESPONSE" | grep -q "success"; then
                echo -e "${GREEN}✅ API测试成功！${NC}"
                SHORT_CODE=$(echo "$RESPONSE" | grep -o '"short_code":"[^"]*"' | cut -d'"' -f4)
                echo -e "${GREEN}🔗 测试短链接: $BASE_URL/$SHORT_CODE${NC}"
            else
                echo -e "${YELLOW}⚠️  API测试失败，但服务可能仍在启动中${NC}"
            fi
            break
        fi
        echo -n "."
        sleep 5
    done
else
    echo -e "${YELLOW}⚠️  容器启动可能有问题，请检查日志${NC}"
fi

echo ""
echo -e "${GREEN}🎉 单容器短链接服务部署完成！${NC}"
echo ""
echo -e "${BLUE}📋 服务信息:${NC}"
echo -e "  🌐 API地址: $BASE_URL"
echo -e "  🔑 API Token: $API_TOKEN"
echo -e "  🗄️  数据库: MySQL (容器内部)"
echo -e "  🚀 缓存: Redis (容器内部)"
echo -e "  📦 架构: 单容器一体化"
echo ""
echo -e "${BLUE}🔧 管理命令:${NC}"
echo -e "  docker-compose -f docker-compose.single.yml logs -f    # 查看日志"
echo -e "  docker-compose -f docker-compose.single.yml restart    # 重启服务"
echo -e "  docker-compose -f docker-compose.single.yml down       # 停止服务"
echo ""
echo -e "${YELLOW}💾 请保存您的API Token: $API_TOKEN${NC}"
