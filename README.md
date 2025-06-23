# Modern ShortLink - 现代化短链接系统

一个基于现代技术栈构建的功能完善的短链接管理系统，提供直观的管理界面、详细的数据分析和企业级的安全保障。

## ✨ 特性

### 🚀 现代化技术栈
- **后端**: Node.js + Fastify + TypeScript + Prisma + PostgreSQL + Redis
- **前端**: React 18 + Vite + TypeScript + Tailwind CSS + React Query
- **部署**: Docker + Docker Compose + Nginx

### 📊 核心功能
- ✅ 短链接创建、管理和分析
- ✅ 用户认证和权限管理
- ✅ 实时访问统计和数据分析
- ✅ 自定义短码和域名支持
- ✅ 密码保护和访问限制
- ✅ 批量操作和标签管理
- ✅ RESTful API 和 Swagger 文档

### 🔒 安全特性
- ✅ JWT 身份认证
- ✅ 密码加密存储
- ✅ 请求限流保护
- ✅ CORS 和安全头配置
- ✅ 输入验证和 SQL 注入防护

### 📈 数据分析
- ✅ 访问统计和趋势分析
- ✅ 地理位置和设备分析
- ✅ 来源和浏览器统计
- ✅ 实时数据更新

## 🚀 快速开始

### 方式一：使用 DockerHub 镜像（推荐）

```bash
# 下载配置文件
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.prod.yml

# 设置环境变量
export DOCKER_USERNAME=your_dockerhub_username
export JWT_SECRET=your_super_secret_jwt_key
export POSTGRES_PASSWORD=your_secure_postgres_password
export REDIS_PASSWORD=your_secure_redis_password

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 运行数据库迁移
docker-compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy
```

### 方式二：从源码构建

```bash
# 克隆项目
git clone https://github.com/nodesire7/short_url.git
cd short_url

# 运行安装脚本
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 方式三：手动安装

#### 1. 环境要求
- Node.js 18+
- Docker & Docker Compose
- Git

#### 2. 安装依赖
```bash
# 安装项目依赖
npm install

# 安装后端依赖
cd backend && npm install && cd ..

# 安装前端依赖
cd frontend && npm install && cd ..
```

#### 3. 环境配置
```bash
# 复制环境变量模板
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# 编辑环境变量（可选）
nano backend/.env
nano frontend/.env
```

#### 4. 启动服务
```bash
# 构建并启动所有服务
docker-compose up -d

# 运行数据库迁移
docker-compose exec backend npx prisma migrate deploy

# 插入种子数据
docker-compose exec backend npm run db:seed
```

## 📋 服务访问

| 服务 | 地址 | 说明 |
|------|------|------|
| 前端界面 | http://localhost:3001 | React 管理界面 |
| 后端API | http://localhost:3000 | Fastify API 服务 |
| API文档 | http://localhost:3000/docs | Swagger 文档 |
| 数据库 | localhost:5432 | PostgreSQL |
| Redis | localhost:6379 | Redis 缓存 |

## 🔑 默认账户

| 角色 | 邮箱 | 密码 | 权限 |
|------|------|------|------|
| 超级管理员 | admin@shortlink.com | admin123456 | 全部权限 |
| 普通用户 | test@shortlink.com | test123456 | 基础功能 |

## 🛠️ 开发指南

### 开发环境启动
```bash
# 启动开发环境
chmod +x scripts/dev.sh
./scripts/dev.sh

# 或者分别启动
npm run dev:backend  # 后端开发服务器
npm run dev:frontend # 前端开发服务器
```

### 项目结构
```
modern-shortlink/
├── backend/                 # 后端 API 服务
│   ├── src/
│   │   ├── controllers/     # 控制器
│   │   ├── routes/         # 路由定义
│   │   ├── plugins/        # Fastify 插件
│   │   ├── utils/          # 工具函数
│   │   └── config/         # 配置文件
│   ├── prisma/             # 数据库模式和迁移
│   └── Dockerfile          # 后端容器配置
├── frontend/               # 前端 React 应用
│   ├── src/
│   │   ├── components/     # React 组件
│   │   ├── pages/          # 页面组件
│   │   ├── stores/         # 状态管理
│   │   ├── lib/            # 工具库
│   │   └── styles/         # 样式文件
│   └── Dockerfile          # 前端容器配置
├── nginx/                  # Nginx 配置
├── scripts/                # 部署脚本
└── docker-compose.yml      # 容器编排配置
```

### 常用命令
```bash
# 开发环境
npm run dev                 # 启动开发环境
npm run build              # 构建项目
npm run test               # 运行测试

# Docker 操作
docker-compose up -d       # 启动所有服务
docker-compose down        # 停止所有服务
docker-compose logs -f     # 查看日志
docker-compose restart     # 重启服务

# 数据库操作
npm run db:migrate         # 运行数据库迁移
npm run db:seed           # 插入种子数据
npm run db:studio         # 打开 Prisma Studio
npm run db:reset          # 重置数据库
```

## 🔧 配置说明

### 环境变量

#### 后端配置 (backend/.env)
```env
# 基础配置
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# 数据库
DATABASE_URL=postgresql://shortlink:password@postgres:5432/shortlink

# Redis
REDIS_URL=redis://:password@redis:6379

# JWT
JWT_SECRET=your_super_secret_jwt_key
JWT_EXPIRES_IN=7d

# 短链接
DEFAULT_DOMAIN=localhost:3000
SHORT_CODE_LENGTH=6

# 功能开关
ENABLE_ANALYTICS=true
```

#### 前端配置 (frontend/.env)
```env
# API 配置
VITE_API_URL=http://localhost:3000/api/v1

# 应用配置
VITE_APP_NAME=Modern ShortLink
VITE_APP_DESCRIPTION=现代化短链接系统
```

## 📊 API 文档

系统提供完整的 RESTful API，支持以下功能：

### 认证相关
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `GET /api/v1/auth/me` - 获取当前用户信息
- `PUT /api/v1/auth/change-password` - 修改密码

### 短链接管理
- `POST /api/v1/links` - 创建短链接
- `GET /api/v1/links` - 获取链接列表
- `GET /api/v1/links/:id` - 获取链接详情
- `PUT /api/v1/links/:id` - 更新链接
- `DELETE /api/v1/links/:id` - 删除链接
- `POST /api/v1/links/batch` - 批量操作

### 数据分析
- `GET /api/v1/analytics/links/:id` - 获取链接分析数据
- `GET /api/v1/users/stats` - 获取用户统计信息

### 短链接访问
- `GET /:shortCode` - 短链接重定向
- `GET /:shortCode/preview` - 短链接预览

详细的 API 文档可在 http://localhost:3000/docs 查看。

## 🚀 部署指南

### 生产环境部署

1. **服务器要求**
   - Ubuntu 20.04+ / CentOS 8+
   - Docker & Docker Compose
   - 2GB+ RAM, 20GB+ 存储

2. **域名配置**
   ```bash
   # 修改 nginx 配置
   nano nginx/nginx.conf

   # 更新 server_name
   server_name your-domain.com;
   ```

3. **SSL 证书**
   ```bash
   # 使用 Let's Encrypt
   certbot --nginx -d your-domain.com

   # 或手动配置证书
   cp your-cert.pem nginx/ssl/cert.pem
   cp your-key.pem nginx/ssl/key.pem
   ```

4. **环境变量**
   ```bash
   # 更新生产环境配置
   nano backend/.env

   # 修改关键配置
   NODE_ENV=production
   JWT_SECRET=your_production_secret
   DEFAULT_DOMAIN=your-domain.com
   ```

5. **启动服务**
   ```bash
   docker-compose -f docker-compose.yml up -d
   ```

### 性能优化

1. **数据库优化**
   - 配置连接池
   - 添加适当索引
   - 定期清理过期数据

2. **缓存策略**
   - Redis 缓存热点数据
   - CDN 加速静态资源
   - 浏览器缓存配置

3. **监控告警**
   - 集成 Prometheus + Grafana
   - 配置日志收集
   - 设置健康检查

## 🔒 安全建议

1. **生产环境安全**
   - 修改默认密码和密钥
   - 启用 HTTPS
   - 配置防火墙规则
   - 定期更新依赖

2. **数据安全**
   - 定期备份数据库
   - 加密敏感数据
   - 限制数据库访问
   - 监控异常访问

3. **应用安全**
   - 输入验证和过滤
   - SQL 注入防护
   - XSS 攻击防护
   - CSRF 令牌验证

## 🛠️ 故障排除

### 常见问题

1. **服务无法启动**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep -E '(3000|3001|5432|6379)'

   # 查看容器日志
   docker-compose logs [service-name]

   # 重新构建镜像
   docker-compose build --no-cache
   ```

2. **数据库连接失败**
   ```bash
   # 检查数据库状态
   docker-compose exec postgres pg_isready

   # 重置数据库
   docker-compose down -v
   docker-compose up -d postgres
   ```

3. **前端页面空白**
   ```bash
   # 检查构建日志
   docker-compose logs frontend

   # 重新构建前端
   cd frontend && npm run build
   ```

### 性能问题

1. **响应缓慢**
   - 检查数据库查询性能
   - 优化 Redis 缓存策略
   - 增加服务器资源

2. **内存占用高**
   - 调整 Node.js 内存限制
   - 优化数据库连接池
   - 清理无用的日志文件

## 📦 发布指南

### 一键发布到 GitHub 和 DockerHub

```bash
# 运行发布脚本
chmod +x scripts/publish.sh
./scripts/publish.sh
```

该脚本会自动：
1. 初始化 Git 仓库
2. 提交代码到 GitHub
3. 构建 Docker 镜像
4. 推送到 DockerHub
5. 生成部署命令

详细发布说明请查看 [DEPLOYMENT.md](DEPLOYMENT.md)

### DockerHub 镜像

- 后端镜像: `nodesire77/shorturl-backend:latest`
- 前端镜像: `nodesire77/shorturl-frontend:latest`

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

### 开发规范

- 使用 TypeScript 进行类型安全开发
- 遵循 ESLint 和 Prettier 代码规范
- 编写单元测试覆盖核心功能
- 提交信息遵循 Conventional Commits 规范

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [jwma/jump-jump](https://github.com/jwma/jump-jump) - 原始项目灵感
- [Fastify](https://www.fastify.io/) - 高性能 Node.js 框架
- [React](https://reactjs.org/) - 用户界面库
- [Prisma](https://www.prisma.io/) - 现代数据库工具包
- [Tailwind CSS](https://tailwindcss.com/) - 实用优先的 CSS 框架

## 📞 支持

如果您在使用过程中遇到问题，可以通过以下方式获取帮助：

- 📧 邮箱: support@example.com
- 💬 讨论: [GitHub Discussions](https://github.com/your-repo/discussions)
- 🐛 问题反馈: [GitHub Issues](https://github.com/your-repo/issues)

---

⭐ 如果这个项目对您有帮助，请给我们一个 Star！
