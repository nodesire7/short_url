#!/bin/bash

# API调试脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

API_TOKEN="TaDeixjf9alwtJe5v4wv7F7cIpXM03hl"
LOCAL_URL="http://localhost:2282"
DOMAIN_URL="https://s.gbtgame.me"

echo -e "${BLUE}🔍 API调试测试${NC}"
echo "=" * 50

# 测试1: 本地健康检查
echo -e "${BLUE}1. 测试本地健康检查...${NC}"
if curl -f "$LOCAL_URL/health" 2>/dev/null; then
    echo -e "${GREEN}✅ 本地健康检查通过${NC}"
else
    echo -e "${RED}❌ 本地健康检查失败${NC}"
fi
echo ""

# 测试2: 域名健康检查
echo -e "${BLUE}2. 测试域名健康检查...${NC}"
if curl -f "$DOMAIN_URL/health" 2>/dev/null; then
    echo -e "${GREEN}✅ 域名健康检查通过${NC}"
else
    echo -e "${RED}❌ 域名健康检查失败${NC}"
fi
echo ""

# 测试3: 本地API创建
echo -e "${BLUE}3. 测试本地API创建...${NC}"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST "$LOCAL_URL/api/create" \
    -H "Authorization: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"url": "https://baidu.com", "title": "百度", "code": "test123"}')

echo "响应内容:"
echo "$RESPONSE"
echo ""

# 测试4: 域名API创建
echo -e "${BLUE}4. 测试域名API创建...${NC}"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST "$DOMAIN_URL/api/create" \
    -H "Authorization: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"url": "https://baidu.com", "title": "百度", "code": "test456"}')

echo "响应内容:"
echo "$RESPONSE"
echo ""

# 测试5: 检查容器日志
echo -e "${BLUE}5. 检查容器日志...${NC}"
echo "最近20行日志:"
docker logs shorturl_api-1 --tail 20
echo ""

# 测试6: 测试不同的HTTP方法
echo -e "${BLUE}6. 测试HTTP方法支持...${NC}"

echo "GET /api/create:"
curl -s -w "HTTP_CODE:%{http_code}\n" -X GET "$DOMAIN_URL/api/create" \
    -H "Authorization: $API_TOKEN"
echo ""

echo "OPTIONS /api/create:"
curl -s -w "HTTP_CODE:%{http_code}\n" -X OPTIONS "$DOMAIN_URL/api/create" \
    -H "Authorization: $API_TOKEN"
echo ""

echo "POST /api/create (无数据):"
curl -s -w "HTTP_CODE:%{http_code}\n" -X POST "$DOMAIN_URL/api/create" \
    -H "Authorization: $API_TOKEN" \
    -H "Content-Type: application/json"
echo ""

# 测试7: 检查反向代理配置
echo -e "${BLUE}7. 检查反向代理响应头...${NC}"
curl -I "$DOMAIN_URL/api/create" 2>/dev/null | head -10
echo ""

# 测试8: 详细的curl调试
echo -e "${BLUE}8. 详细curl调试...${NC}"
curl -v -X POST "$DOMAIN_URL/api/create" \
    -H "Authorization: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"url": "https://baidu.com", "title": "百度", "code": "debug123"}' \
    2>&1 | head -30
echo ""

echo -e "${YELLOW}调试完成！请检查上述输出找出问题所在。${NC}"
