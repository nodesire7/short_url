# 🔗 短链接API服务

一个功能完整的短链接生成和管理API服务，包含MySQL + Redis + API的一体化容器。

## ✨ 特性

- 🚀 **一体化容器**: MySQL + Redis + API全在一个容器内，零端口冲突
- 🛡️ **安全可靠**: API Token认证，SQL注入防护
- 📊 **数据统计**: 点击统计，访问记录
- 🐳 **零配置部署**: 一键启动，无需复杂配置
- ⚡ **高性能**: 内置MySQL数据库 + Redis缓存
- 📝 **完整API**: RESTful接口，支持CRUD操作
- 🔥 **简化架构**: 单容器解决方案，易于管理和部署

## 🚀 一键部署

### 方案1: 使用一键脚本（推荐）

```bash
# 下载并运行一键脚本
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/start-single.sh
chmod +x start-single.sh
./start-single.sh
```

### 方案2: 直接使用docker-compose

```bash
# 下载配置文件
curl -O https://raw.githubusercontent.com/nodesire7/short_url/main/docker-compose.single.yml

# 设置API Token
export API_TOKEN=$(openssl rand -hex 32)

# 启动服务
docker-compose -f docker-compose.single.yml up -d

echo "API Token: $API_TOKEN"
echo "服务地址: http://localhost:2282"
```

## 📋 环境变量配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `API_TOKEN` | 必需 | API认证令牌（自动生成） |
| `BASE_URL` | `http://localhost:2282` | 服务基础URL |
| `SHORT_CODE_LENGTH` | `6` | 短代码长度 |
| `LOG_LEVEL` | `INFO` | 日志级别 |

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

## � 管理命令

```bash
# 查看服务状态
docker-compose -f docker-compose.single.yml ps

# 查看日志
docker-compose -f docker-compose.single.yml logs -f

# 重启服务
docker-compose -f docker-compose.single.yml restart

# 停止服务
docker-compose -f docker-compose.single.yml down
```

## � 架构优势

- **🔥 零端口冲突**: 所有服务在一个容器内
- **📦 简化管理**: 只需管理一个容器
- **🚀 高性能**: MySQL + Redis 内置优化
- **⚡ 快速部署**: 真正的一键启动
- **🛡️ 数据安全**: 容器内部通信，无外部暴露

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License
