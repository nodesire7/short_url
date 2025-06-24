# 构建阶段
FROM node:18-alpine as builder

# 设置工作目录
WORKDIR /app

# 复制package文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM node:18-alpine

# 安装serve
RUN npm install -g serve

# 设置工作目录
WORKDIR /app

# 从构建阶段复制构建结果
COPY --from=builder /app/dist ./dist

# 创建启动脚本
RUN echo '#!/bin/sh' > start.sh && \
    echo 'serve -s dist -l 8848 -n' >> start.sh && \
    chmod +x start.sh

# 暴露端口
EXPOSE 8848

# 启动命令
CMD ["./start.sh"]
