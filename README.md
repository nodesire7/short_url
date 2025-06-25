# 🔗 短链接API服务

一个功能完整的短链接生成和管理API服务，支持多种数据库和缓存方案。

## ✨ 特性

- 🚀 **高性能**: 支持MySQL + Redis缓存
- 🛡️ **安全可靠**: API Token认证，SQL注入防护
- 📊 **数据统计**: 点击统计，访问记录
- 🐳 **容器化**: Docker一键部署
- 🔧 **灵活配置**: 支持SQLite/MySQL，可选Redis缓存
- 🌐 **反向代理**: 内置Nginx配置
- 📝 **完整API**: RESTful接口，支持CRUD操作

## 🚀 快速开始

### 方案1: 完整版（推荐）
包含MySQL + Redis + Nginx，生产级部署：

```bash
# 下载启动脚本
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/start-full-stack.sh
chmod +x start-full-stack.sh

# 启动完整服务栈
./start-full-stack.sh
```

### 方案2: SQLite版（简单）
单容器部署，避免权限问题：

```bash
# 下载配置文件
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.sqlite.yml

# 设置API Token
export API_TOKEN=$(openssl rand -hex 32)

# 启动服务
docker-compose -f docker-compose.sqlite.yml up -d

echo "API Token: $API_TOKEN"
echo "服务地址: http://localhost:2282"
```

### 方案3: 1Panel用户（解决权限问题）
```yaml
services:
  shorturl_api:
    ports:
      - 2282:2282
    environment:
      - API_TOKEN=your-secure-token
      - BASE_URL=https://your-domain.com
      - DB_TYPE=sqlite
      - DATABASE_PATH=/tmp/shortlinks.db  # 使用临时目录避免权限问题
    image: nodesire77/shorturl_api:latest
```

## 📋 环境变量配置

### 基本配置
| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `API_TOKEN` | 必需 | API认证令牌 |
| `BASE_URL` | `http://localhost:2282` | 服务基础URL |
| `SHORT_CODE_LENGTH` | `6` | 短代码长度 |
| `LOG_LEVEL` | `INFO` | 日志级别 |

### 数据库配置
| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `DB_TYPE` | `sqlite` | 数据库类型 (sqlite/mysql) |
| `DATABASE_PATH` | `/app/data/shortlinks.db` | SQLite数据库路径 |
| `MYSQL_HOST` | `localhost` | MySQL主机 |
| `MYSQL_PORT` | `3306` | MySQL端口 |
| `MYSQL_USER` | `shortlink` | MySQL用户名 |
| `MYSQL_PASSWORD` | `shortlink123456` | MySQL密码 |
| `MYSQL_DATABASE` | `shortlink` | MySQL数据库名 |

### Redis配置
| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `REDIS_HOST` | `localhost` | Redis主机 |
| `REDIS_PORT` | `6379` | Redis端口 |
| `REDIS_PASSWORD` | `` | Redis密码 |
| `REDIS_DB` | `0` | Redis数据库编号 |
| `CACHE_TTL` | `3600` | 缓存过期时间(秒) |

## 🔧 API接口

### 认证
所有API请求需要在Header中包含API Token：
```
Authorization: YOUR_API_TOKEN
```

### 创建短链接
```bash
curl -X POST http://localhost:2282/api/create \
  -H "Authorization: YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.example.com",
    "title": "示例网站",
    "code": "custom"
  }'
```

### 获取链接列表
```bash
curl -X GET "http://localhost:2282/api/list?page=1&limit=20" \
  -H "Authorization: YOUR_API_TOKEN"
```

### 获取链接详情
```bash
curl -X GET http://localhost:2282/api/info/abc123 \
  -H "Authorization: YOUR_API_TOKEN"
```

### 删除链接
```bash
curl -X DELETE http://localhost:2282/api/delete/abc123 \
  -H "Authorization: YOUR_API_TOKEN"
```

### 获取统计信息
```bash
curl -X GET http://localhost:2282/api/stats \
  -H "Authorization: YOUR_API_TOKEN"
```

### 健康检查
```bash
curl http://localhost:2282/health
```

## 🔍 故障排除

### SQLite权限问题
如果遇到 "database is locked" 或 "readonly database" 错误：

```bash
# 方案1: 使用临时目录
export DATABASE_PATH=/tmp/shortlinks.db

# 方案2: 使用内存数据库
export DATABASE_PATH=:memory:

# 方案3: 修复权限
sudo chown -R 1000:1000 ./data
chmod 755 ./data
```

### MySQL连接问题
```bash
# 检查MySQL服务
docker logs shortlink-mysql
docker exec shortlink-mysql mysqladmin ping
```

### Redis连接问题
```bash
# 检查Redis服务
docker logs shortlink-redis
docker exec shortlink-redis redis-cli ping
```

## 📊 监控和日志

### 查看服务日志
```bash
# API服务日志
docker logs shortlink-api -f

# 完整栈日志
docker-compose -f docker-compose.full.yml logs -f
```

### 健康检查
```bash
# API健康检查
curl http://localhost:2282/health

# 通过Nginx
curl http://localhost/health
```

## 🔒 安全建议

1. **使用强API Token**: 至少32位随机字符
2. **HTTPS部署**: 生产环境使用SSL证书
3. **防火墙配置**: 限制数据库端口访问
4. **定期备份**: 备份MySQL数据和配置
5. **监控日志**: 关注异常访问和错误

## 📈 性能优化

1. **使用Redis缓存**: 减少数据库查询
2. **MySQL调优**: 适当配置连接池和缓存
3. **Nginx优化**: 启用gzip压缩和缓存
4. **监控指标**: 使用Prometheus + Grafana

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License
