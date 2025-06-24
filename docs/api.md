# API文档

## 基础信息

- **Base URL**: `http://your-domain.com/api/v1`
- **认证方式**: Bearer Token (JWT)
- **数据格式**: JSON
- **字符编码**: UTF-8

## 认证接口

### 用户登录

**POST** `/auth/login`

请求体：
```json
{
  "username": "admin@shortlink.com",
  "password": "admin123456"
}
```

响应：
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 604800,
  "user": {
    "id": 1,
    "email": "admin@shortlink.com",
    "username": "管理员",
    "role": "admin",
    "avatar": null
  }
}
```

### 用户注册

**POST** `/auth/register`

请求体：
```json
{
  "email": "user@example.com",
  "username": "用户名",
  "password": "password123"
}
```

### 获取当前用户信息

**GET** `/auth/me`

需要认证。

响应：
```json
{
  "id": 1,
  "email": "admin@shortlink.com",
  "username": "管理员",
  "role": "admin",
  "status": "active",
  "avatar": null,
  "last_login_at": "2024-01-01T12:00:00Z",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

### 更新用户信息

**PUT** `/auth/me`

需要认证。

请求体：
```json
{
  "username": "新用户名",
  "avatar": "头像URL",
  "password": "新密码"
}
```

## 短链接管理

### 创建短链接

**POST** `/links`

需要认证。

请求体：
```json
{
  "original_url": "https://www.example.com",
  "short_code": "abc123",
  "title": "示例网站",
  "description": "这是一个示例网站",
  "expires_at": "2024-12-31T23:59:59Z",
  "password": "访问密码",
  "tags": ["tag1", "tag2"]
}
```

响应：
```json
{
  "id": 1,
  "short_code": "abc123",
  "original_url": "https://www.example.com",
  "short_url": "http://your-domain.com/abc123",
  "title": "示例网站",
  "description": "这是一个示例网站",
  "domain": "your-domain.com",
  "expires_at": "2024-12-31T23:59:59Z",
  "is_active": true,
  "click_count": 0,
  "password": null,
  "tags": ["tag1", "tag2"],
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

### 获取短链接列表

**GET** `/links`

需要认证。

查询参数：
- `page`: 页码 (默认: 1)
- `size`: 每页数量 (默认: 20)
- `search`: 搜索关键词
- `status`: 状态筛选 (active/inactive/expired)
- `sort`: 排序字段 (created_at/click_count/title)
- `order`: 排序方向 (asc/desc)

响应：
```json
{
  "links": [...],
  "total": 100,
  "page": 1,
  "size": 20,
  "pages": 5
}
```

### 获取短链接详情

**GET** `/links/{link_id}`

需要认证。

### 更新短链接

**PUT** `/links/{link_id}`

需要认证。

### 删除短链接

**DELETE** `/links/{link_id}`

需要认证。

### 批量操作

**POST** `/links/batch`

需要认证。

请求体：
```json
{
  "action": "delete|activate|deactivate",
  "link_ids": [1, 2, 3]
}
```

## 短链接重定向

### 访问短链接

**GET** `/{short_code}`

无需认证。

- 如果链接有效，返回302重定向到原始URL
- 如果链接无效，返回404错误
- 如果链接需要密码，返回密码验证页面

### 密码验证

**POST** `/{short_code}/verify`

请求体：
```json
{
  "password": "访问密码"
}
```

## 统计分析

### 获取总体统计

**GET** `/stats/overview`

需要认证。

响应：
```json
{
  "total_links": 156,
  "total_clicks": 12847,
  "total_users": 23,
  "today_clicks": 342,
  "this_week_clicks": 2156,
  "this_month_clicks": 8934
}
```

### 获取链接统计

**GET** `/stats/links/{link_id}`

需要认证。

响应：
```json
{
  "link_id": 1,
  "total_clicks": 1234,
  "unique_clicks": 856,
  "click_history": [
    {
      "date": "2024-01-01",
      "clicks": 45
    }
  ],
  "top_countries": [
    {
      "country": "中国",
      "clicks": 567
    }
  ],
  "top_browsers": [
    {
      "browser": "Chrome",
      "clicks": 789
    }
  ],
  "top_devices": [
    {
      "device": "Desktop",
      "clicks": 890
    }
  ]
}
```

### 获取访问记录

**GET** `/stats/clicks`

需要认证。管理员可查看所有记录，普通用户只能查看自己的。

查询参数：
- `link_id`: 链接ID
- `start_date`: 开始日期
- `end_date`: 结束日期
- `page`: 页码
- `size`: 每页数量

## 用户管理（管理员）

### 获取用户列表

**GET** `/users`

需要管理员权限。

### 创建用户

**POST** `/users`

需要管理员权限。

### 更新用户

**PUT** `/users/{user_id}`

需要管理员权限。

### 删除用户

**DELETE** `/users/{user_id}`

需要管理员权限。

## 系统配置（管理员）

### 获取配置列表

**GET** `/config`

需要管理员权限。

### 更新配置

**PUT** `/config/{config_key}`

需要管理员权限。

请求体：
```json
{
  "config_value": "新配置值"
}
```

## 错误响应

所有错误响应格式：

```json
{
  "error": "错误信息",
  "code": "ERROR_CODE",
  "details": "详细信息（可选）"
}
```

常见错误码：
- `VALIDATION_ERROR`: 数据验证失败 (400)
- `AUTHENTICATION_ERROR`: 认证失败 (401)
- `AUTHORIZATION_ERROR`: 权限不足 (403)
- `NOT_FOUND_ERROR`: 资源不存在 (404)
- `CONFLICT_ERROR`: 资源冲突 (409)
- `RATE_LIMIT_ERROR`: 请求过于频繁 (429)
- `INTERNAL_ERROR`: 服务器内部错误 (500)

## 请求示例

### 使用curl

```bash
# 登录获取token
curl -X POST http://your-domain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@shortlink.com","password":"admin123456"}'

# 创建短链接
curl -X POST http://your-domain.com/api/v1/links \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"original_url":"https://www.example.com","short_code":"test123"}'
```

### 使用JavaScript

```javascript
// 登录
const loginResponse = await fetch('/api/v1/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    username: 'admin@shortlink.com',
    password: 'admin123456'
  })
});

const { access_token } = await loginResponse.json();

// 创建短链接
const linkResponse = await fetch('/api/v1/links', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${access_token}`
  },
  body: JSON.stringify({
    original_url: 'https://www.example.com',
    short_code: 'test123'
  })
});
```
