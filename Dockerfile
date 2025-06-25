# 多阶段构建：包含MySQL 5.7、Redis和API的一体化容器
FROM ubuntu:20.04

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装基础工具
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    debconf-utils \
    && rm -rf /var/lib/apt/lists/*

# 添加MySQL 5.7 APT仓库
RUN wget -O /tmp/mysql-apt-config.deb https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb \
    && echo "mysql-apt-config mysql-apt-config/select-server select mysql-5.7" | debconf-set-selections \
    && echo "mysql-apt-config mysql-apt-config/select-product select Ok" | debconf-set-selections \
    && dpkg -i /tmp/mysql-apt-config.deb \
    && rm /tmp/mysql-apt-config.deb

# 更新包列表
RUN apt-get update

# 预配置MySQL安装
RUN echo "mysql-server-5.7 mysql-server/root_password password " | debconf-set-selections \
    && echo "mysql-server-5.7 mysql-server/root_password_again password " | debconf-set-selections

# 安装MySQL 5.7
RUN apt-get install -y \
    mysql-server-5.7 \
    mysql-client-5.7 \
    && rm -rf /var/lib/apt/lists/*

# 安装其他系统依赖
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    redis-server \
    curl \
    supervisor \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制Python依赖
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY app.py .
COPY gunicorn.conf.py .

# 创建必要目录
RUN mkdir -p /app/data /app/logs /var/log/supervisor

# 配置MySQL 5.7
RUN service mysql start && \
    mysql -e "CREATE DATABASE IF NOT EXISTS shortlink;" && \
    mysql -e "CREATE USER 'shortlink'@'localhost' IDENTIFIED BY 'shortlink123456';" && \
    mysql -e "GRANT ALL PRIVILEGES ON shortlink.* TO 'shortlink'@'localhost';" && \
    mysql -e "FLUSH PRIVILEGES;" && \
    service mysql stop

# 配置Redis
RUN sed -i 's/^daemonize no/daemonize yes/' /etc/redis/redis.conf && \
    sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf && \
    sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf

# 创建supervisor配置
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 创建启动脚本
COPY container-start.sh /start.sh
RUN chmod +x /start.sh

# 暴露端口
EXPOSE 2282

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:2282/health || exit 1

# 启动命令
CMD ["/start.sh"]
