#!/bin/bash

# 简单短链接API启动脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 启动简单短链接API服务${NC}"

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Python3 未安装，请先安装 Python3${NC}"
    exit 1
fi

# 创建虚拟环境（如果不存在）
if [ ! -d "venv" ]; then
    echo -e "${BLUE}📦 创建Python虚拟环境...${NC}"
    python3 -m venv venv
fi

# 激活虚拟环境
echo -e "${BLUE}🔧 激活虚拟环境...${NC}"
source venv/bin/activate

# 安装依赖
echo -e "${BLUE}📚 安装依赖包...${NC}"
pip install -r requirements.txt

# 创建数据目录
mkdir -p data

# 启动服务
echo -e "${GREEN}🎉 启动短链接API服务...${NC}"
echo -e "${BLUE}📡 服务地址: http://localhost:2282${NC}"
echo -e "${BLUE}🔑 认证令牌: TaDeixjf9alwtJe5v4wv7F7cIpXM03hl${NC}"
echo -e "${BLUE}📚 API文档: http://localhost:2282${NC}"
echo ""
echo -e "${YELLOW}按 Ctrl+C 停止服务${NC}"
echo ""

python app.py
