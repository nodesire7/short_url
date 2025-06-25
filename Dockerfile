FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 创建应用用户（使用常见的UID/GID）
RUN groupadd -g 1000 appuser && useradd -u 1000 -g appuser -m appuser

# 创建必要目录并设置权限
RUN mkdir -p /app/data /app/logs \
    && chmod 777 /app/data /app/logs \
    && chown -R appuser:appuser /app

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY app.py .
COPY gunicorn.conf.py .
COPY docker-entrypoint.sh .

# 设置启动脚本权限
RUN chmod +x docker-entrypoint.sh

# 设置权限
RUN chown -R appuser:appuser /app

# 切换到应用用户
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:2282/health || exit 1

# 暴露端口
EXPOSE 2282

# 启动命令
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD []
