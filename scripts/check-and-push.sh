#!/bin/bash

# 检查仓库状态并推送的脚本

set -e

echo "🔍 检查GitHub仓库状态..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查GitHub仓库是否存在
check_github_repo() {
    echo -e "${BLUE}📋 检查GitHub仓库...${NC}"
    
    if curl -s -f -o /dev/null https://github.com/nodesire7/short_url; then
        echo -e "${GREEN}✅ GitHub仓库已存在${NC}"
        return 0
    else
        echo -e "${RED}❌ GitHub仓库不存在${NC}"
        echo -e "${YELLOW}请先创建GitHub仓库：${NC}"
        echo "1. 访问 https://github.com/nodesire7"
        echo "2. 点击 '+' → 'New repository'"
        echo "3. 仓库名: short_url"
        echo "4. 描述: Modern Short URL System - 现代化短链接管理系统"
        echo "5. 选择 Public，不勾选任何额外选项"
        echo "6. 点击 'Create repository'"
        echo ""
        read -p "创建完成后按回车继续..."
        return 1
    fi
}

# 检查DockerHub仓库是否存在
check_dockerhub_repos() {
    echo -e "${BLUE}📋 检查DockerHub仓库...${NC}"
    
    backend_exists=false
    frontend_exists=false
    
    if curl -s -f -o /dev/null https://hub.docker.com/r/nodesire77/shorturl-backend; then
        echo -e "${GREEN}✅ 后端镜像仓库已存在${NC}"
        backend_exists=true
    else
        echo -e "${RED}❌ 后端镜像仓库不存在${NC}"
    fi
    
    if curl -s -f -o /dev/null https://hub.docker.com/r/nodesire77/shorturl-frontend; then
        echo -e "${GREEN}✅ 前端镜像仓库已存在${NC}"
        frontend_exists=true
    else
        echo -e "${RED}❌ 前端镜像仓库不存在${NC}"
    fi
    
    if [ "$backend_exists" = false ] || [ "$frontend_exists" = false ]; then
        echo -e "${YELLOW}请先创建DockerHub仓库：${NC}"
        echo "1. 访问 https://hub.docker.com/u/nodesire77"
        echo "2. 点击 'Create Repository'"
        echo "3. 创建 'shorturl-backend' 仓库（Public）"
        echo "4. 创建 'shorturl-frontend' 仓库（Public）"
        echo ""
        read -p "创建完成后按回车继续..."
        return 1
    fi
    
    return 0
}

# 推送代码到GitHub
push_to_github() {
    echo -e "${BLUE}🚀 推送代码到GitHub...${NC}"
    
    # 检查是否有未提交的更改
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo -e "${YELLOW}⚠️ 发现未提交的更改，正在提交...${NC}"
        git add .
        git commit -m "update: Final configuration for publication"
    fi
    
    # 推送代码
    if git push -u origin main; then
        echo -e "${GREEN}✅ 代码推送成功${NC}"
        
        # 创建版本标签
        git tag v1.0.0 2>/dev/null || echo -e "${YELLOW}⚠️ 标签v1.0.0已存在${NC}"
        git push origin v1.0.0 2>/dev/null || echo -e "${YELLOW}⚠️ 标签已推送${NC}"
        
        return 0
    else
        echo -e "${RED}❌ 代码推送失败${NC}"
        return 1
    fi
}

# 检查Docker是否可用
check_docker() {
    echo -e "${BLUE}🐳 检查Docker...${NC}"
    
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker已安装${NC}"
        
        if docker info &> /dev/null; then
            echo -e "${GREEN}✅ Docker服务正在运行${NC}"
            return 0
        else
            echo -e "${RED}❌ Docker服务未运行，请启动Docker${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Docker未安装${NC}"
        echo "请安装Docker后再运行此脚本"
        return 1
    fi
}

# 构建并推送Docker镜像
build_and_push_images() {
    echo -e "${BLUE}🔨 构建并推送Docker镜像...${NC}"
    
    # 登录DockerHub
    echo -e "${YELLOW}请输入DockerHub密码:${NC}"
    if ! docker login -u nodesire77; then
        echo -e "${RED}❌ DockerHub登录失败${NC}"
        return 1
    fi
    
    # 构建后端镜像
    echo -e "${BLUE}🔨 构建后端镜像...${NC}"
    if docker build -t nodesire77/shorturl-backend:latest -t nodesire77/shorturl-backend:v1.0.0 ./backend; then
        echo -e "${GREEN}✅ 后端镜像构建成功${NC}"
    else
        echo -e "${RED}❌ 后端镜像构建失败${NC}"
        return 1
    fi
    
    # 构建前端镜像
    echo -e "${BLUE}🔨 构建前端镜像...${NC}"
    if docker build -t nodesire77/shorturl-frontend:latest -t nodesire77/shorturl-frontend:v1.0.0 ./frontend; then
        echo -e "${GREEN}✅ 前端镜像构建成功${NC}"
    else
        echo -e "${RED}❌ 前端镜像构建失败${NC}"
        return 1
    fi
    
    # 推送后端镜像
    echo -e "${BLUE}📤 推送后端镜像...${NC}"
    docker push nodesire77/shorturl-backend:latest
    docker push nodesire77/shorturl-backend:v1.0.0
    
    # 推送前端镜像
    echo -e "${BLUE}📤 推送前端镜像...${NC}"
    docker push nodesire77/shorturl-frontend:latest
    docker push nodesire77/shorturl-frontend:v1.0.0
    
    echo -e "${GREEN}✅ 所有镜像推送成功${NC}"
    return 0
}

# 显示完成信息
show_completion() {
    echo ""
    echo -e "${GREEN}🎉 发布完成！${NC}"
    echo ""
    echo -e "${BLUE}📋 发布信息:${NC}"
    echo "   GitHub: https://github.com/nodesire7/short_url"
    echo "   后端镜像: https://hub.docker.com/r/nodesire77/shorturl-backend"
    echo "   前端镜像: https://hub.docker.com/r/nodesire77/shorturl-frontend"
    echo ""
    echo -e "${BLUE}🚀 快速部署命令:${NC}"
    echo "   curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.prod.yml"
    echo "   export DOCKER_USERNAME=nodesire77"
    echo "   docker-compose -f docker-compose.prod.yml up -d"
    echo ""
}

# 主函数
main() {
    echo -e "${GREEN}🚀 开始发布 Modern Short URL 系统...${NC}"
    echo ""
    
    # 检查并等待GitHub仓库创建
    while ! check_github_repo; do
        echo -e "${YELLOW}等待GitHub仓库创建...${NC}"
        sleep 5
    done
    
    # 检查并等待DockerHub仓库创建
    while ! check_dockerhub_repos; do
        echo -e "${YELLOW}等待DockerHub仓库创建...${NC}"
        sleep 5
    done
    
    # 推送代码到GitHub
    if ! push_to_github; then
        echo -e "${RED}❌ GitHub推送失败，请检查权限设置${NC}"
        exit 1
    fi
    
    # 检查Docker
    if check_docker; then
        # 构建并推送Docker镜像
        if build_and_push_images; then
            show_completion
        else
            echo -e "${RED}❌ Docker镜像推送失败${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️ Docker不可用，跳过镜像构建${NC}"
        echo -e "${BLUE}💡 你可以稍后手动构建镜像，或等待GitHub Actions自动构建${NC}"
        show_completion
    fi
}

# 运行主函数
main
