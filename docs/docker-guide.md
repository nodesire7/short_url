# Docker 部署指南

## 概述

短链接管理系统提供了多种Docker部署方式，支持本地构建和使用预构建镜像。

## 🚀 快速开始（推荐）

### 使用预构建镜像

最简单的部署方式，无需本地构建：

```bash
# 下载快速部署脚本
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/quick-deploy.sh
chmod +x quick-deploy.sh

# 一键部署
./quick-deploy.sh
```

### 手动使用预构建镜像

```bash
# 下载docker-compose配置
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.hub.yml

# 启动服务
docker-compose -f docker-compose.hub.yml up -d
```

## 🏗️ 本地构建

### 方式1：使用构建脚本

```bash
# 克隆项目
git clone https://github.com/nodesire7/short_url.git
cd short_url

# 本地构建
./docker-build.sh build

# 构建并推送到Docker Hub
DOCKER_USERNAME=your-username ./docker-build.sh push
```

### 方式2：使用docker-compose

```bash
# 本地构建并启动
docker-compose up -d --build
```

## 📦 Docker镜像

### 官方镜像

- **后端镜像**: `nodesire7/shortlink-backend:latest`
- **前端镜像**: `nodesire7/shortlink-frontend:latest`

### 镜像特性

- ✅ 多架构支持 (AMD64/ARM64)
- ✅ 自动构建和发布
- ✅ 安全扫描
- ✅ 最小化镜像大小

### 拉取镜像

```bash
# 拉取后端镜像
docker pull nodesire7/shortlink-backend:latest

# 拉取前端镜像
docker pull nodesire7/shortlink-frontend:latest
```

## 🔧 配置选项

### 环境变量

#### 后端配置

```bash
# 数据库配置
DATABASE_URL=mysql+pymysql://user:password@host:port/database
DB_HOST=mysql
DB_PORT=3306
DB_NAME=shortlink
DB_USER=shortlink
DB_PASSWORD=password

# 应用配置
SECRET_KEY=your-secret-key
HOST=0.0.0.0
PORT=9848
DEBUG=False
DEFAULT_DOMAIN=your-domain.com

# Redis配置
REDIS_URL=redis://redis:6379/0

# CORS配置
CORS_ORIGINS=["http://localhost:8848"]
```

#### 前端配置

```bash
# API配置
VITE_API_URL=http://localhost:9848
VITE_DEFAULT_DOMAIN=localhost:8848

# 应用配置
VITE_APP_TITLE=短链接管理系统
```

### 数据卷

```yaml
volumes:
  # MySQL数据
  mysql_data:/var/lib/mysql
  
  # Redis数据
  redis_data:/data
  
  # 后端日志
  backend_logs:/app/logs
  
  # 上传文件
  backend_uploads:/app/uploads
```

## 🌐 网络配置

### 端口映射

- **前端**: 8848 → 8848
- **后端**: 9848 → 9848
- **MySQL**: 3306 → 3306
- **Redis**: 6379 → 6379

### 自定义端口

```bash
# 修改端口映射
docker-compose -f docker-compose.hub.yml up -d \
  -p "8080:8848" \  # 前端端口
  -p "8081:9848"    # 后端端口
```

## 🔄 CI/CD 自动构建

### GitHub Actions

项目配置了自动构建流程：

1. **触发条件**:
   - 推送到 `main` 分支
   - 创建版本标签
   - 手动触发

2. **构建流程**:
   - 多架构构建 (AMD64/ARM64)
   - 自动推送到Docker Hub
   - 缓存优化

3. **配置Secrets**:
   ```
   DOCKER_USERNAME: Docker Hub用户名
   DOCKER_PASSWORD: Docker Hub密码
   ```

### 手动触发构建

在GitHub仓库页面：
1. 进入 "Actions" 标签
2. 选择 "Build and Push Docker Images"
3. 点击 "Run workflow"

## 🛠️ 故障排除

### 常见问题

#### 1. 镜像拉取失败

```bash
# 检查网络连接
docker pull hello-world

# 使用镜像加速器
# 配置Docker daemon.json
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
```

#### 2. 容器启动失败

```bash
# 查看容器日志
docker-compose -f docker-compose.hub.yml logs backend
docker-compose -f docker-compose.hub.yml logs frontend

# 检查容器状态
docker-compose -f docker-compose.hub.yml ps
```

#### 3. 数据库连接失败

```bash
# 检查MySQL容器
docker-compose -f docker-compose.hub.yml logs mysql

# 手动连接测试
docker exec -it shortlink-mysql mysql -u shortlink -p
```

#### 4. 端口冲突

```bash
# 检查端口占用
netstat -tulpn | grep :8848
netstat -tulpn | grep :9848

# 修改端口映射
# 编辑 docker-compose.hub.yml 文件
```

### 性能优化

#### 1. 资源限制

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

#### 2. 健康检查

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:9848/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## 📊 监控和日志

### 日志管理

```bash
# 查看实时日志
docker-compose -f docker-compose.hub.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.hub.yml logs backend
docker-compose -f docker-compose.hub.yml logs frontend

# 限制日志大小
docker-compose -f docker-compose.hub.yml logs --tail=100
```

### 监控指标

```bash
# 查看容器资源使用
docker stats

# 查看容器详细信息
docker inspect shortlink-backend
docker inspect shortlink-frontend
```

## 🔐 安全建议

### 1. 环境变量安全

- 使用 `.env` 文件管理敏感信息
- 不要在代码中硬编码密码
- 定期轮换密钥和密码

### 2. 网络安全

- 使用内部网络通信
- 限制对外暴露的端口
- 配置防火墙规则

### 3. 镜像安全

- 定期更新基础镜像
- 扫描镜像漏洞
- 使用官方镜像

## 📚 相关文档

- [部署指南](deployment.md)
- [API文档](api.md)
- [用户指南](user-guide.md)
- [Docker官方文档](https://docs.docker.com/)

## 🆘 获取帮助

如遇问题，请：

1. 查看本文档的故障排除部分
2. 检查GitHub Issues
3. 提交新的Issue描述问题
