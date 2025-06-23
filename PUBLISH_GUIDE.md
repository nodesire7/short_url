# 🚀 完整发布指南

## 📋 准备工作

### 1. 创建GitHub仓库

1. 访问 https://github.com/nodesire7
2. 点击右上角的 "+" 号，选择 "New repository"
3. 填写仓库信息：
   - Repository name: `short_url`
   - Description: `Modern Short URL System - 现代化短链接管理系统`
   - 选择 Public
   - **不要**勾选任何额外选项（README、.gitignore、License）
4. 点击 "Create repository"

### 2. 创建DockerHub仓库

#### 后端镜像仓库
1. 访问 https://hub.docker.com/u/nodesire77
2. 点击 "Create Repository"
3. 填写信息：
   - Name: `shorturl-backend`
   - Description: `Modern Short URL System - Backend API`
   - Visibility: Public
4. 点击 "Create"

#### 前端镜像仓库
1. 再次点击 "Create Repository"
2. 填写信息：
   - Name: `shorturl-frontend`
   - Description: `Modern Short URL System - Frontend UI`
   - Visibility: Public
3. 点击 "Create"

## 🔧 第二步：配置GitHub Secrets（用于自动化）

1. 进入你的GitHub仓库 https://github.com/nodesire7/short_url
2. 点击 "Settings" 标签
3. 在左侧菜单中点击 "Secrets and variables" → "Actions"
4. 点击 "New repository secret" 添加以下secrets：

   - **DOCKER_USERNAME**: `nodesire77`
   - **DOCKER_PASSWORD**: 你的DockerHub访问令牌

### 获取DockerHub访问令牌：
1. 登录 https://hub.docker.com
2. 点击右上角头像 → "Account Settings"
3. 点击 "Security" 标签
4. 点击 "New Access Token"
5. 输入描述（如：GitHub Actions）
6. 选择权限：Read, Write, Delete
7. 点击 "Generate"
8. 复制生成的令牌（只显示一次）

## 🚀 第三步：推送代码

创建好GitHub仓库后，在终端运行：

```bash
# 推送代码到GitHub
git push -u origin main

# 创建版本标签
git tag v1.0.0
git push origin v1.0.0
```

## 🐳 第四步：构建和推送Docker镜像

### 方式一：手动构建推送

```bash
# 登录DockerHub
docker login -u nodesire77

# 构建后端镜像
docker build -t nodesire77/shorturl-backend:latest -t nodesire77/shorturl-backend:v1.0.0 ./backend

# 构建前端镜像
docker build -t nodesire77/shorturl-frontend:latest -t nodesire77/shorturl-frontend:v1.0.0 ./frontend

# 推送后端镜像
docker push nodesire77/shorturl-backend:latest
docker push nodesire77/shorturl-backend:v1.0.0

# 推送前端镜像
docker push nodesire77/shorturl-frontend:latest
docker push nodesire77/shorturl-frontend:v1.0.0
```

### 方式二：自动化构建（推荐）

推送代码到GitHub后，GitHub Actions会自动：
1. 构建Docker镜像
2. 推送到DockerHub
3. 创建多个标签（latest、版本号等）

## 📋 第五步：验证发布

### 检查GitHub
- 访问 https://github.com/nodesire7/short_url
- 确认代码已上传
- 检查 Actions 标签页的构建状态

### 检查DockerHub
- 访问 https://hub.docker.com/r/nodesire77/shorturl-backend
- 访问 https://hub.docker.com/r/nodesire77/shorturl-frontend
- 确认镜像已推送成功

## 🎯 第六步：测试部署

创建测试目录并部署：

```bash
# 创建测试目录
mkdir test-deployment
cd test-deployment

# 下载配置文件
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.prod.yml

# 设置环境变量
export DOCKER_USERNAME=nodesire77
export JWT_SECRET=test_jwt_secret_$(date +%s)
export POSTGRES_PASSWORD=test_postgres_$(openssl rand -hex 8)
export REDIS_PASSWORD=test_redis_$(openssl rand -hex 8)

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 等待服务启动
sleep 30

# 运行数据库迁移
docker-compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy

# 访问测试
echo "前端: http://localhost:3001"
echo "API: http://localhost:3000"
echo "文档: http://localhost:3000/docs"
```

## 📚 第七步：更新文档

确保以下文档中的链接正确：
- README.md
- QUICK_START.md
- DEPLOYMENT.md

## 🎉 完成！

发布完成后，用户可以通过以下方式使用你的系统：

### 快速部署
```bash
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.prod.yml
export DOCKER_USERNAME=nodesire77
docker-compose -f docker-compose.prod.yml up -d
```

### 从源码构建
```bash
git clone https://github.com/nodesire7/short_url.git
cd short_url
chmod +x scripts/setup.sh
./scripts/setup.sh
```

## 📞 支持链接

- GitHub仓库: https://github.com/nodesire7/short_url
- 后端镜像: https://hub.docker.com/r/nodesire77/shorturl-backend
- 前端镜像: https://hub.docker.com/r/nodesire77/shorturl-frontend
- 问题反馈: https://github.com/nodesire7/short_url/issues

---

按照这个指南，你的Modern Short URL系统就可以成功发布到GitHub和DockerHub了！
