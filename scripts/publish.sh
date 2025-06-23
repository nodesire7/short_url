#!/bin/bash

# Short URL 项目发布脚本
# 自动发布到 GitHub 和 DockerHub

set -e

echo "🚀 开始发布 Short URL 项目..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查必要的工具
check_requirements() {
    echo -e "${BLUE}📋 检查必要工具...${NC}"
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git 未安装${NC}"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安装${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 工具检查通过${NC}"
}

# 获取用户输入
get_user_input() {
    echo -e "${BLUE}📝 请输入发布信息...${NC}"
    
    read -p "GitHub 用户名: " GITHUB_USERNAME
    read -p "DockerHub 用户名: " DOCKER_USERNAME
    read -p "项目版本 (默认: v1.0.0): " VERSION
    VERSION=${VERSION:-v1.0.0}
    
    echo -e "${YELLOW}⚠️ 请确保已在 GitHub 仓库中配置了以下 Secrets:${NC}"
    echo "  - DOCKER_USERNAME: $DOCKER_USERNAME"
    echo "  - DOCKER_PASSWORD: 你的 DockerHub Access Token"
    echo ""
    read -p "是否已配置 GitHub Secrets? (y/N): " SECRETS_CONFIGURED
    
    if [[ ! $SECRETS_CONFIGURED =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}请先配置 GitHub Secrets，然后重新运行此脚本${NC}"
        echo "配置路径: 仓库 → Settings → Secrets and variables → Actions"
        exit 1
    fi
}

# 初始化 Git 仓库
init_git() {
    echo -e "${BLUE}🔧 初始化 Git 仓库...${NC}"
    
    if [ ! -d ".git" ]; then
        git init
        echo -e "${GREEN}✅ Git 仓库初始化完成${NC}"
    else
        echo -e "${YELLOW}⚠️ Git 仓库已存在${NC}"
    fi
    
    # 检查是否有远程仓库
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin https://github.com/$GITHUB_USERNAME/short_url.git
        echo -e "${GREEN}✅ 添加远程仓库${NC}"
    else
        echo -e "${YELLOW}⚠️ 远程仓库已存在${NC}"
    fi
}

# 提交代码
commit_code() {
    echo -e "${BLUE}📦 提交代码...${NC}"
    
    # 添加所有文件
    git add .
    
    # 检查是否有变更
    if git diff --staged --quiet; then
        echo -e "${YELLOW}⚠️ 没有新的变更需要提交${NC}"
    else
        git commit -m "feat: Modern Short URL System $VERSION

- 🚀 现代化技术栈 (Node.js + React + TypeScript)
- 📊 完整的短链接管理功能
- 🔒 企业级安全保障
- 📈 详细的数据分析
- 🐳 Docker 容器化部署
- 📚 完整的 API 文档"
        echo -e "${GREEN}✅ 代码提交完成${NC}"
    fi
}

# 推送到 GitHub
push_to_github() {
    echo -e "${BLUE}🚀 推送到 GitHub...${NC}"
    
    # 设置主分支
    git branch -M main
    
    # 推送代码
    git push -u origin main
    
    # 创建标签
    git tag $VERSION
    git push origin $VERSION
    
    echo -e "${GREEN}✅ 代码已推送到 GitHub${NC}"
    echo -e "${BLUE}📍 仓库地址: https://github.com/$GITHUB_USERNAME/short_url${NC}"
}

# 构建并推送 Docker 镜像
build_and_push_docker() {
    echo -e "${BLUE}🐳 构建并推送 Docker 镜像...${NC}"
    
    # 登录 DockerHub
    echo -e "${YELLOW}请输入 DockerHub 密码:${NC}"
    docker login -u $DOCKER_USERNAME
    
    # 构建后端镜像
    echo -e "${BLUE}🔨 构建后端镜像...${NC}"
    docker build -t $DOCKER_USERNAME/shorturl-backend:latest -t $DOCKER_USERNAME/shorturl-backend:$VERSION ./backend
    
    # 构建前端镜像
    echo -e "${BLUE}🔨 构建前端镜像...${NC}"
    docker build -t $DOCKER_USERNAME/shorturl-frontend:latest -t $DOCKER_USERNAME/shorturl-frontend:$VERSION ./frontend
    
    # 推送镜像
    echo -e "${BLUE}📤 推送后端镜像...${NC}"
    docker push $DOCKER_USERNAME/shorturl-backend:latest
    docker push $DOCKER_USERNAME/shorturl-backend:$VERSION
    
    echo -e "${BLUE}📤 推送前端镜像...${NC}"
    docker push $DOCKER_USERNAME/shorturl-frontend:latest
    docker push $DOCKER_USERNAME/shorturl-frontend:$VERSION
    
    echo -e "${GREEN}✅ Docker 镜像已推送到 DockerHub${NC}"
    echo -e "${BLUE}📍 后端镜像: https://hub.docker.com/r/$DOCKER_USERNAME/shorturl-backend${NC}"
    echo -e "${BLUE}📍 前端镜像: https://hub.docker.com/r/$DOCKER_USERNAME/shorturl-frontend${NC}"
}

# 生成部署命令
generate_deploy_commands() {
    echo -e "${BLUE}📋 生成部署命令...${NC}"
    
    cat > deploy-commands.txt << EOF
# Short URL 部署命令

## 使用 DockerHub 镜像快速部署

# 1. 设置环境变量
export DOCKER_USERNAME=$DOCKER_USERNAME
export JWT_SECRET=your_super_secret_jwt_key_change_this
export POSTGRES_PASSWORD=your_secure_postgres_password
export REDIS_PASSWORD=your_secure_redis_password

# 2. 下载配置文件
curl -O https://raw.githubusercontent.com/$GITHUB_USERNAME/short_url/main/docker-compose.prod.yml

# 3. 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 4. 运行数据库迁移
docker-compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy

# 5. 访问应用
echo "前端界面: http://localhost:3001"
echo "后端API: http://localhost:3000"
echo "API文档: http://localhost:3000/docs"

## 默认账户
# 管理员: admin@shortlink.com / admin123456
# 测试用户: test@shortlink.com / test123456
EOF
    
    echo -e "${GREEN}✅ 部署命令已生成到 deploy-commands.txt${NC}"
}

# 显示完成信息
show_completion_info() {
    echo ""
    echo -e "${GREEN}🎉 Short URL 项目发布完成！${NC}"
    echo ""
    echo -e "${BLUE}📋 发布信息:${NC}"
    echo -e "   版本: $VERSION"
    echo -e "   GitHub: https://github.com/$GITHUB_USERNAME/short_url"
    echo -e "   DockerHub 后端: https://hub.docker.com/r/$DOCKER_USERNAME/shorturl-backend"
    echo -e "   DockerHub 前端: https://hub.docker.com/r/$DOCKER_USERNAME/shorturl-frontend"
    echo ""
    echo -e "${BLUE}🚀 快速部署:${NC}"
    echo -e "   查看 deploy-commands.txt 文件获取部署命令"
    echo ""
    echo -e "${BLUE}📚 下一步:${NC}"
    echo -e "   1. 在 GitHub 仓库中查看 Actions 构建状态"
    echo -e "   2. 使用生成的部署命令在服务器上部署"
    echo -e "   3. 配置域名和 SSL 证书"
    echo -e "   4. 设置监控和备份"
    echo ""
}

# 主函数
main() {
    check_requirements
    get_user_input
    init_git
    commit_code
    push_to_github
    build_and_push_docker
    generate_deploy_commands
    show_completion_info
}

# 运行主函数
main
