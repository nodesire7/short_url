# 短链接管理系统部署指南

## 系统要求

### 硬件要求
- CPU: 2核心以上
- 内存: 4GB以上
- 存储: 20GB以上可用空间
- 网络: 稳定的互联网连接

### 软件要求
- Docker 20.10+
- Docker Compose 2.0+
- 1Panel (推荐)

## 1Panel部署（推荐）

### 步骤1：准备项目文件

1. 将项目文件上传到服务器
```bash
# 上传项目到服务器
scp -r ShortLink/ user@your-server:/opt/
```

2. 进入项目目录
```bash
cd /opt/ShortLink
```

### 步骤2：配置环境变量

1. 复制环境变量模板
```bash
cp docker/.env.example docker/.env
```

2. 编辑环境变量
```bash
nano docker/.env
```

重要配置项：
```env
# 域名配置（必须修改）
DEFAULT_DOMAIN=your-domain.com
FRONTEND_PORT=8848
BACKEND_PORT=9848

# 数据库密码（必须修改）
MYSQL_ROOT_PASSWORD=your-strong-password
MYSQL_PASSWORD=your-strong-password

# JWT密钥（必须修改）
SECRET_KEY=your-super-secret-key-at-least-32-characters
```

### 步骤3：在1Panel中部署

1. 登录1Panel管理面板
2. 进入"容器" -> "编排"
3. 点击"创建编排"
4. 选择项目目录：`/opt/ShortLink`
5. 选择编排文件：`docker/1panel-compose.yml`
6. 设置项目名称：`shortlink`
7. 点击"确认创建"

### 步骤4：配置反向代理

1. 在1Panel中进入"网站"
2. 创建新网站
3. 域名：`your-domain.com`
4. 类型：反向代理
5. 代理地址：`http://127.0.0.1:8848`

### 步骤5：配置SSL证书（可选）

1. 在网站设置中申请SSL证书
2. 或上传自有证书
3. 开启HTTPS重定向

## Docker Compose部署

### 快速部署

1. 克隆项目
```bash
git clone <repository-url>
cd ShortLink
```

2. 启动服务
```bash
docker-compose up -d
```

3. 查看服务状态
```bash
docker-compose ps
```

### 自定义部署

1. 修改配置文件
```bash
# 复制环境变量文件
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# 编辑配置
nano backend/.env
nano frontend/.env
```

2. 构建并启动
```bash
docker-compose build
docker-compose up -d
```

## 手动部署

### 后端部署

1. 安装Python环境
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-pip python3-venv

# CentOS/RHEL
sudo yum install python3 python3-pip
```

2. 创建虚拟环境
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
```

3. 安装依赖
```bash
pip install -r requirements.txt
```

4. 配置环境变量
```bash
cp .env.example .env
nano .env
```

5. 初始化数据库
```bash
# 确保MySQL已安装并运行
# 创建数据库
mysql -u root -p < ../database/init.sql
```

6. 启动服务
```bash
python main.py
```

### 前端部署

1. 安装Node.js
```bash
# 使用NodeSource仓库
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

2. 安装依赖
```bash
cd frontend
npm install
```

3. 构建项目
```bash
npm run build
```

4. 部署到Web服务器
```bash
# 使用nginx
sudo cp -r dist/* /var/www/html/
```

## 数据库配置

### MySQL配置

1. 创建数据库用户
```sql
CREATE USER 'shortlink'@'%' IDENTIFIED BY 'your-password';
GRANT ALL PRIVILEGES ON shortlink.* TO 'shortlink'@'%';
FLUSH PRIVILEGES;
```

2. 导入初始数据
```bash
mysql -u shortlink -p shortlink < database/init.sql
```

### 备份策略

1. 自动备份脚本
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u shortlink -p shortlink > backup_$DATE.sql
```

2. 设置定时任务
```bash
crontab -e
# 每天凌晨2点备份
0 2 * * * /path/to/backup.sh
```

## 监控和维护

### 日志查看

```bash
# Docker部署
docker-compose logs -f backend
docker-compose logs -f frontend

# 手动部署
tail -f backend/logs/app.log
```

### 性能监控

1. 系统资源监控
```bash
# 查看容器资源使用
docker stats

# 查看系统资源
htop
```

2. 应用监控
- 访问 `http://your-domain.com/health` 检查后端健康状态
- 监控数据库连接数和查询性能

### 故障排除

常见问题：

1. **数据库连接失败**
   - 检查数据库服务是否运行
   - 验证连接配置和密码

2. **前端无法访问后端**
   - 检查CORS配置
   - 验证API地址配置

3. **JWT认证失败**
   - 检查SECRET_KEY配置
   - 验证令牌是否过期

## 安全建议

1. **修改默认密码**
   - 数据库密码
   - 管理员账号密码
   - JWT密钥

2. **启用HTTPS**
   - 申请SSL证书
   - 配置HTTPS重定向

3. **防火墙配置**
   - 只开放必要端口
   - 限制数据库访问

4. **定期更新**
   - 更新系统补丁
   - 更新Docker镜像

## 扩展配置

### 负载均衡

使用Nginx配置多实例负载均衡：

```nginx
upstream backend {
    server backend1:9848;
    server backend2:9848;
}

upstream frontend {
    server frontend1:8848;
    server frontend2:8848;
}
```

### Redis集群

配置Redis主从或集群模式提高可用性。

### CDN配置

将静态资源部署到CDN提高访问速度。
