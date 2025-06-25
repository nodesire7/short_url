# 生产级短链接API服务

高性能、高可用的短链接API服务，支持Docker和Systemd两种部署方式。

## 🚀 特性

### 核心功能
- ✅ **RESTful API**: 完整的CRUD操作
- ✅ **高性能**: Gunicorn + Gevent异步处理
- ✅ **负载均衡**: Nginx反向代理
- ✅ **数据库连接池**: SQLite连接池优化
- ✅ **访问统计**: 详细的点击统计和分析
- ✅ **自定义代码**: 支持自定义短链接代码

### 生产特性
- ✅ **日志系统**: 结构化日志和日志轮转
- ✅ **健康检查**: 内置健康检查接口
- ✅ **安全防护**: 限流、安全头、输入验证
- ✅ **监控告警**: 系统监控和性能指标
- ✅ **容器化**: Docker容器化部署
- ✅ **服务管理**: Systemd服务管理

### 性能优化
- ✅ **连接池**: 数据库连接池
- ✅ **异步处理**: Gevent异步I/O
- ✅ **缓存策略**: Nginx缓存优化
- ✅ **限流保护**: API限流和DDoS防护

## 📋 API接口

### 认证
所有API请求需要在Header中包含：
```
Authorization: YOUR_API_TOKEN
Content-Type: application/json
```

**注意**: API_TOKEN需要在部署时通过环境变量配置。

### 接口列表

#### 1. 创建短链接
```http
POST /api/create
```

请求体：
```json
{
  "url": "https://www.example.com",
  "title": "示例网站",
  "code": "custom"  // 可选，自定义短代码
}
```

#### 2. 获取链接列表
```http
GET /api/list?page=1&limit=20
```

#### 3. 获取链接统计
```http
GET /api/stats/{short_code}
```

#### 4. 删除短链接
```http
DELETE /api/delete/{short_code}
```

#### 5. 短链接重定向
```http
GET /{short_code}
```

#### 6. 健康检查
```http
GET /health
```

## 🛠️ 部署方式

### 方式1：Docker部署（推荐）

```bash
# 进入项目目录
cd production

# 配置环境变量（首次部署会自动生成）
cp .env.example .env
# 编辑 .env 文件，设置 API_TOKEN

# 一键部署
./deploy.sh docker

# 带优化和安全加固
./deploy.sh docker optimize security
```

### 方式2：Systemd部署

```bash
# 进入项目目录
cd production

# 一键部署
./deploy.sh systemd

# 带优化和安全加固
./deploy.sh systemd optimize security
```

### 方式3：手动Docker部署

```bash
# 构建镜像
docker build -t shortlink-api .

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps
```

## 📊 服务配置

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| API_TOKEN | 无 | API认证令牌（必需） |
| BASE_URL | http://localhost:2282 | 基础URL |
| SHORT_CODE_LENGTH | 6 | 短代码长度 |
| LOG_LEVEL | INFO | 日志级别 |

### 端口配置

| 服务 | 端口 | 说明 |
|------|------|------|
| API服务 | 2282 | 主API服务 |
| Nginx | 80 | HTTP代理 |
| Nginx | 443 | HTTPS代理（可选） |

### 目录结构

```
production/
├── app.py                 # 主应用文件
├── requirements.txt       # Python依赖
├── gunicorn.conf.py      # Gunicorn配置
├── nginx.conf            # Nginx配置
├── Dockerfile            # Docker镜像
├── docker-compose.yml    # Docker编排
├── deploy.sh             # 部署脚本
├── systemd/              # Systemd配置
│   └── shortlink-api.service
├── data/                 # 数据目录
│   └── shortlinks.db
└── logs/                 # 日志目录
    ├── app.log
    ├── gunicorn_access.log
    └── gunicorn_error.log
```

## 🔧 管理命令

### Docker管理

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 更新服务
docker-compose pull && docker-compose up -d
```

### Systemd管理

```bash
# 查看服务状态
systemctl status shortlink-api

# 重启服务
systemctl restart shortlink-api

# 停止服务
systemctl stop shortlink-api

# 查看日志
journalctl -u shortlink-api -f

# 重新加载配置
systemctl reload shortlink-api
```

## 📈 性能指标

### 基准测试

- **并发连接**: 1000+
- **QPS**: 5000+
- **响应时间**: <10ms (P95)
- **内存使用**: <100MB
- **CPU使用**: <50% (4核)

### 监控指标

- API响应时间
- 请求成功率
- 数据库连接数
- 内存和CPU使用率
- 磁盘I/O
- 网络流量

## 🔒 安全特性

### 访问控制
- API Token认证
- IP白名单（可选）
- 请求限流
- DDoS防护

### 数据安全
- SQL注入防护
- XSS防护
- CSRF防护
- 输入验证

### 系统安全
- 最小权限原则
- 安全头配置
- 日志审计
- 定期安全更新

## 🚨 故障排除

### 常见问题

#### 1. 服务启动失败
```bash
# 检查日志
docker-compose logs shortlink-api
# 或
journalctl -u shortlink-api -n 50
```

#### 2. 数据库连接错误
```bash
# 检查数据目录权限
ls -la data/
# 检查磁盘空间
df -h
```

#### 3. Nginx代理错误
```bash
# 检查Nginx配置
nginx -t
# 检查Nginx日志
tail -f /var/log/nginx/shortlink_error.log
```

#### 4. 性能问题
```bash
# 检查系统资源
top
htop
# 检查网络连接
netstat -tulpn | grep 2282
```

### 日志分析

```bash
# 查看API访问日志
tail -f logs/gunicorn_access.log

# 查看应用错误日志
tail -f logs/app.log

# 查看Nginx访问日志
tail -f logs/nginx_access.log

# 分析错误率
grep "ERROR" logs/app.log | wc -l
```

## 📞 技术支持

### 系统要求
- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+)
- **Python**: 3.8+
- **内存**: 512MB+
- **磁盘**: 1GB+
- **网络**: 公网IP（可选）

### 依赖服务
- Docker 20.10+ (Docker部署)
- Nginx 1.18+ (Systemd部署)
- Python 3.8+ (Systemd部署)

### 联系方式
- 文档: 查看本README
- 日志: 检查应用日志
- 监控: 查看健康检查接口

---

**部署命令**: `./deploy.sh docker`
**服务地址**: http://localhost:2282
**认证令牌**: 通过环境变量配置
**管理界面**: http://localhost:2282

## 🐳 Docker Hub

Docker镜像已发布到: [nodesire77/shorturl_api](https://hub.docker.com/r/nodesire77/shorturl_api)

```bash
# 直接使用Docker镜像
docker run -d -p 2282:2282 \
  -e API_TOKEN=your-secure-token \
  -v $(pwd)/data:/app/data \
  nodesire77/shorturl_api:latest
```
