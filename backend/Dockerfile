# 多阶段构建 Dockerfile for Node.js Backend

# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

# 复制 package 文件
COPY package*.json ./
COPY prisma ./prisma/

# 安装依赖
RUN npm install --only=production && npm cache clean --force

# 生成 Prisma 客户端
RUN npx prisma generate

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM node:18-alpine AS production

# 安装 curl 用于健康检查
RUN apk add --no-cache curl

WORKDIR /app

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs
RUN adduser -S shortlink -u 1001

# 复制构建产物和依赖
COPY --from=builder --chown=shortlink:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=shortlink:nodejs /app/dist ./dist
COPY --from=builder --chown=shortlink:nodejs /app/prisma ./prisma
COPY --from=builder --chown=shortlink:nodejs /app/package*.json ./

# 创建日志目录
RUN mkdir -p /app/logs && chown -R shortlink:nodejs /app/logs

# 切换到非 root 用户
USER shortlink

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# 启动命令
CMD ["node", "dist/index.js"]
