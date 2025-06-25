FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 创建必要目录并设置权限
RUN mkdir -p /app/data /app/logs \
    && chmod 777 /app/data /app/logs

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY app.py .
COPY gunicorn.conf.py .

# 设置权限
RUN chmod -R 755 /app

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:2282/health || exit 1

# 暴露端口
EXPOSE 2282

# 启动命令
CMD ["gunicorn", "--config", "gunicorn.conf.py", "app:app"]
