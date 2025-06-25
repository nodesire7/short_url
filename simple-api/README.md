# 简单短链接API服务

一个轻量级、高效的短链接API服务，使用Python Flask构建。

## 🚀 特性

- ✅ **简单高效**: 单文件Python应用，轻量级SQLite数据库
- ✅ **API认证**: 使用Authorization头进行安全认证
- ✅ **完整功能**: 创建、查询、统计、删除短链接
- ✅ **访问统计**: 记录点击次数、IP地址、用户代理
- ✅ **自定义代码**: 支持自定义短链接代码
- ✅ **Docker支持**: 提供Docker和docker-compose部署

## 📋 API接口

### 认证
所有API请求需要在Header中包含：
```
Authorization: TaDeixjf9alwtJe5v4wv7F7cIpXM03hl
Content-Type: application/json
```

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

响应：
```json
{
  "success": true,
  "short_code": "abc123",
  "short_url": "http://localhost:2282/abc123",
  "original_url": "https://www.example.com",
  "title": "示例网站",
  "created_at": "2024-06-24T10:30:00"
}
```

#### 2. 获取链接列表
```http
GET /api/list?page=1&limit=20
```

响应：
```json
{
  "success": true,
  "links": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5
  }
}
```

#### 3. 获取链接统计
```http
GET /api/stats/{short_code}
```

响应：
```json
{
  "success": true,
  "short_code": "abc123",
  "short_url": "http://localhost:2282/abc123",
  "original_url": "https://www.example.com",
  "click_count": 156,
  "recent_clicks": [...]
}
```

#### 4. 删除短链接
```http
DELETE /api/delete/{short_code}
```

#### 5. 短链接重定向
```http
GET /{short_code}
```
自动重定向到原始URL并记录访问统计。

#### 6. 健康检查
```http
GET /health
```

## 🛠️ 部署方式

### 方式1：直接运行（推荐）

```bash
# 进入项目目录
cd simple-api

# 运行启动脚本
./start.sh
```

### 方式2：手动运行

```bash
# 安装依赖
pip install -r requirements.txt

# 启动服务
python app.py
```

### 方式3：Docker部署

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 方式4：Docker手动构建

```bash
# 构建镜像
docker build -t shortlink-api .

# 运行容器
docker run -d -p 2282:2282 -v $(pwd)/data:/app/data shortlink-api
```

## 📊 使用示例

### 创建短链接

```bash
curl -X POST http://localhost:2282/api/create \
  -H "Authorization: TaDeixjf9alwtJe5v4wv7F7cIpXM03hl" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com",
    "title": "Google搜索",
    "code": "google"
  }'
```

### 获取链接列表

```bash
curl -X GET http://localhost:2282/api/list \
  -H "Authorization: TaDeixjf9alwtJe5v4wv7F7cIpXM03hl"
```

### 访问短链接

```bash
curl -L http://localhost:2282/google
```

### 获取统计信息

```bash
curl -X GET http://localhost:2282/api/stats/google \
  -H "Authorization: TaDeixjf9alwtJe5v4wv7F7cIpXM03hl"
```

## 🔧 配置说明

### 环境变量

可以通过修改 `app.py` 中的配置：

```python
API_TOKEN = "TaDeixjf9alwtJe5v4wv7F7cIpXM03hl"  # API认证令牌
DATABASE = "shortlinks.db"                      # 数据库文件
BASE_URL = "http://localhost:2282"              # 基础URL
SHORT_CODE_LENGTH = 6                           # 短代码长度
```

### 数据存储

- 使用SQLite数据库存储数据
- 数据库文件：`shortlinks.db`
- 支持数据持久化

## 📈 性能特点

- **轻量级**: 单文件应用，启动快速
- **高效**: SQLite数据库，读写性能优秀
- **稳定**: 简单架构，故障点少
- **易维护**: 代码简洁，易于理解和修改

## 🔒 安全特性

- API Token认证
- URL格式验证
- SQL注入防护
- 输入参数验证

## 📝 日志和监控

- 访问日志记录
- 健康检查接口
- 错误处理和响应

## 🎯 适用场景

- 个人或小团队使用
- 内部系统短链接服务
- 简单的URL缩短需求
- 快速原型开发

## 📞 技术支持

如有问题，请检查：
1. Python版本 >= 3.7
2. 端口2282是否被占用
3. 文件权限是否正确
4. 依赖包是否安装完整

---

**服务地址**: http://localhost:2282  
**认证令牌**: TaDeixjf9alwtJe5v4wv7F7cIpXM03hl  
**API文档**: http://localhost:2282
