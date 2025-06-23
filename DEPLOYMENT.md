# 部署指南

本文档详细说明如何将 Short URL 项目发布到 GitHub 和 DockerHub。

## 📋 准备工作

### 1. GitHub 准备
- 确保你有 GitHub 账户
- 创建新的仓库 `short_url`
- 获取 GitHub Personal Access Token（用于 CI/CD）

### 2. DockerHub 准备
- 注册 DockerHub 账户
- 记录你的 DockerHub 用户名
- 获取 DockerHub Access Token

## 🚀 发布到 GitHub

### 1. 初始化 Git 仓库
```bash
# 在项目根目录执行
git init
git add .
git commit -m "Initial commit: Modern Short URL System"
```

### 2. 添加远程仓库
```bash
# 替换 YOUR_USERNAME 为你的 GitHub 用户名
git remote add origin https://github.com/YOUR_USERNAME/short_url.git
git branch -M main
git push -u origin main
```

### 3. 配置 GitHub Secrets
在 GitHub 仓库设置中添加以下 Secrets：

- `DOCKER_USERNAME`: 你的 DockerHub 用户名
- `DOCKER_PASSWORD`: 你的 DockerHub Access Token

路径：仓库 → Settings → Secrets and variables → Actions → New repository secret

## 🐳 发布到 DockerHub

### 方式一：自动发布（推荐）

项目已配置 GitHub Actions，当你推送代码到 `main` 分支时会自动构建并推送到 DockerHub。

### 方式二：手动发布

#### 1. 登录 DockerHub
```bash
docker login
```

#### 2. 构建镜像
```bash
# 构建后端镜像
docker build -t YOUR_USERNAME/shorturl-backend:latest ./backend

# 构建前端镜像
docker build -t YOUR_USERNAME/shorturl-frontend:latest ./frontend
```

#### 3. 推送镜像
```bash
# 推送后端镜像
docker push YOUR_USERNAME/shorturl-backend:latest

# 推送前端镜像
docker push YOUR_USERNAME/shorturl-frontend:latest
```

## 🔧 生产环境部署

### 1. 使用 DockerHub 镜像部署
```bash
# 设置环境变量
export DOCKER_USERNAME=your_dockerhub_username
export JWT_SECRET=your_super_secret_jwt_key
export POSTGRES_PASSWORD=your_postgres_password
export REDIS_PASSWORD=your_redis_password

# 使用生产配置启动
docker-compose -f docker-compose.prod.yml up -d
```

### 2. 使用部署脚本
```bash
# 设置环境变量
export DOCKER_USERNAME=your_dockerhub_username

# 运行部署脚本
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## 📝 环境变量配置

### 必需的环境变量
```bash
# DockerHub 用户名
DOCKER_USERNAME=your_dockerhub_username

# JWT 密钥（生产环境必须修改）
JWT_SECRET=your_super_secret_jwt_key_change_this

# 数据库密码
POSTGRES_PASSWORD=your_secure_postgres_password

# Redis 密码
REDIS_PASSWORD=your_secure_redis_password
```

### 可选的环境变量
```bash
# 域名配置
DEFAULT_DOMAIN=your-domain.com
CORS_ORIGIN=https://your-domain.com

# 限流配置
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW=900000
```

## 🔒 安全配置

### 1. 生产环境安全检查清单
- [ ] 修改默认的 JWT_SECRET
- [ ] 设置强密码给数据库和 Redis
- [ ] 配置防火墙规则
- [ ] 启用 HTTPS
- [ ] 定期更新依赖包
- [ ] 配置日志监控

### 2. SSL 证书配置
```bash
# 使用 Let's Encrypt
certbot --nginx -d your-domain.com

# 或者手动配置证书
mkdir -p nginx/ssl
cp your-cert.pem nginx/ssl/cert.pem
cp your-key.pem nginx/ssl/key.pem
```

## 📊 监控和维护

### 1. 查看服务状态
```bash
# 查看所有服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看服务日志
docker-compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.prod.yml logs -f backend
```

### 2. 数据备份
```bash
# 备份数据库
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U shorturl shorturl > backup.sql

# 备份 Redis 数据
docker-compose -f docker-compose.prod.yml exec redis redis-cli --rdb /data/dump.rdb
```

### 3. 更新部署
```bash
# 拉取最新镜像
docker-compose -f docker-compose.prod.yml pull

# 重启服务
docker-compose -f docker-compose.prod.yml up -d
```

## 🛠️ 故障排除

### 1. 镜像构建失败
```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建镜像
docker-compose build --no-cache
```

### 2. 服务启动失败
```bash
# 检查日志
docker-compose logs [service-name]

# 检查网络连接
docker network ls
docker network inspect shorturl_shorturl-network
```

### 3. 数据库连接问题
```bash
# 检查数据库状态
docker-compose exec postgres pg_isready -U shorturl

# 重置数据库
docker-compose down -v
docker-compose up -d postgres
```

## 📞 支持

如果在部署过程中遇到问题，可以：

1. 查看项目 Issues: https://github.com/YOUR_USERNAME/short_url/issues
2. 查看 GitHub Actions 构建日志
3. 检查 DockerHub 镜像状态

## 🎯 下一步

部署完成后，你可以：

1. 配置自定义域名
2. 设置 SSL 证书
3. 配置监控和告警
4. 优化性能配置
5. 设置定期备份
