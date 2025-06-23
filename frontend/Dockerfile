# 多阶段构建 Dockerfile for React Frontend

# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

# 复制 package 文件
COPY package*.json ./

# 安装依赖
RUN npm install && npm cache clean --force

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM nginx:alpine AS production

# 复制自定义 nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs
RUN adduser -S shortlink -u 1001

# 设置权限
RUN chown -R shortlink:nodejs /usr/share/nginx/html
RUN chown -R shortlink:nodejs /var/cache/nginx
RUN chown -R shortlink:nodejs /var/log/nginx
RUN chown -R shortlink:nodejs /etc/nginx/conf.d
RUN touch /var/run/nginx.pid
RUN chown -R shortlink:nodejs /var/run/nginx.pid

# 切换到非 root 用户
USER shortlink

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# 启动命令
CMD ["nginx", "-g", "daemon off;"]
