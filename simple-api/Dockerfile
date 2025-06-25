FROM python:3.11-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY app.py .

# 创建数据目录
RUN mkdir -p /app/data

# 暴露端口
EXPOSE 2282

# 设置环境变量
ENV PYTHONUNBUFFERED=1

# 启动应用
CMD ["python", "app.py"]
