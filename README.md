# 短链接管理系统

一个功能完整的短链接管理系统，支持管理员和普通用户两种角色，提供短链接创建、管理、统计等功能。

## 系统特性

- 🔐 **用户管理**: 支持管理员和普通用户两种角色
- 🔗 **短链接管理**: 4-10位可配置长度的短链接
- ⏰ **有效期控制**: 支持设置失效日期或永久有效
- 🌐 **域名配置**: 可自定义短链接域名
- 📊 **访问统计**: 详细的访问数据分析
- 🎨 **现代界面**: 基于React的响应式管理界面

## 技术栈

### 前端
- React 18
- Vite
- Ant Design
- Axios
- React Router

### 后端
- Node.js
- Express
- MySQL
- JWT认证
- bcrypt加密

### 部署
- Docker
- 1Panel支持
- Nginx反向代理

## 项目结构

```
ShortLink/
├── frontend/          # 前端React应用
├── backend/           # 后端API服务
├── database/          # 数据库初始化脚本
├── docker/            # Docker配置文件
├── docs/              # 项目文档
└── README.md
```

## 快速开始

### 一键启动（推荐）

使用提供的启动脚本：

```bash
# 给脚本执行权限
chmod +x start.sh

# 启动系统
./start.sh

# 查看其他选项
./start.sh help
```

### 手动部署

#### 开发环境

1. 启动后端服务
```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# 编辑 .env 配置数据库等信息
python main.py
```

2. 启动前端服务
```bash
cd frontend
npm install
cp .env.example .env
# 编辑 .env 配置API地址
npm run dev
```

#### 生产部署

使用Docker Compose一键部署：

```bash
docker-compose up -d
```

#### 1Panel部署

```bash
# 复制1Panel专用配置
cp docker/1panel-compose.yml docker-compose.yml
cp docker/.env.example .env
# 编辑环境变量后在1Panel中创建编排
```

## 配置说明

### 环境变量

后端环境变量配置（backend/.env）：
```
DATABASE_URL=mysql+pymysql://root:password@localhost:3306/shortlink
SECRET_KEY=your-super-secret-key-change-this-in-production
HOST=0.0.0.0
PORT=9848
DEFAULT_DOMAIN=localhost:9848
```

前端环境变量配置（frontend/.env）：
```
VITE_API_URL=http://0.0.0.0:9848
VITE_APP_TITLE=短链接管理系统
VITE_DEFAULT_DOMAIN=localhost:9848
```

### 默认账号

- **管理员邮箱**: admin@shortlink.com
- **管理员密码**: admin123456

⚠️ **重要**: 部署到生产环境前请务必修改默认密码和JWT密钥！

## 功能说明

### 用户角色

- **管理员**: 可以管理所有用户和短链接，查看系统统计
- **普通用户**: 只能管理自己创建的短链接

### 短链接功能

- 自定义短链接或系统自动生成
- 设置有效期（永久或指定日期）
- 访问统计和分析
- 批量管理操作

## API文档

详细的API文档请查看 [docs/api.md](docs/api.md)

## 许可证

MIT License
