# 🚀 快速开始指南

## 📋 准备工作

确保你的系统已安装：
- Docker
- Docker Compose

## ⚡ 1分钟快速部署

### 一键部署（推荐）
```bash
curl -s https://raw.githubusercontent.com/nodesire7/short_url/main/quick-deploy.sh | bash
```

### 手动部署
```bash
# 1. 下载配置文件
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.prod.yml

# 2. 启动服务（无需任何配置）
docker-compose -f docker-compose.prod.yml up -d

# 3. 等待服务启动并初始化数据库
sleep 30
docker-compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy
```

### 6. 访问应用
- 前端界面: http://localhost:8848
- 后端API: http://localhost:9848
- API文档: http://localhost:9848/docs

## 🔑 默认账户

| 角色 | 邮箱 | 密码 |
|------|------|------|
| 管理员 | admin@shortlink.com | admin123456 |
| 普通用户 | test@shortlink.com | test123456 |

## 🛠️ 常用命令

```bash
# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f

# 停止服务
docker-compose -f docker-compose.prod.yml down

# 重启服务
docker-compose -f docker-compose.prod.yml restart

# 更新到最新版本
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 自定义配置

### 修改域名
编辑 docker-compose.prod.yml 文件中的环境变量：
```bash
# 修改后端配置中的域名设置
DEFAULT_DOMAIN: your-domain.com
CORS_ORIGIN: https://your-domain.com
```

### 配置 SSL
1. 将证书文件放到 `nginx/ssl/` 目录
2. 修改 `nginx/nginx.conf` 启用 HTTPS

### 数据备份
```bash
# 备份数据库
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U shorturl shorturl > backup.sql

# 恢复数据库
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U shorturl shorturl < backup.sql
```

## ❓ 故障排除

### 服务无法启动
```bash
# 检查端口占用
netstat -tlnp | grep -E '(3000|3001|5432|6379)'

# 查看详细日志
docker-compose -f docker-compose.prod.yml logs [service-name]
```

### 数据库连接失败
```bash
# 重启数据库
docker-compose -f docker-compose.prod.yml restart postgres

# 检查数据库状态
docker-compose -f docker-compose.prod.yml exec postgres pg_isready -U shorturl
```

### 前端页面无法访问
```bash
# 重启前端服务
docker-compose -f docker-compose.prod.yml restart frontend

# 检查 Nginx 配置
docker-compose -f docker-compose.prod.yml exec nginx nginx -t
```

## 📞 获取帮助

- 📚 完整文档: [README.md](README.md)
- 🚀 部署指南: [DEPLOYMENT.md](DEPLOYMENT.md)
- 🐛 问题反馈: [GitHub Issues](https://github.com/nodesire7/short_url/issues)

---

🎉 恭喜！你的短链接系统已经成功部署并运行！
