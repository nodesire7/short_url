import Fastify from 'fastify'
import { PrismaClient } from '@prisma/client'
import { config } from './config'
import { registerPlugins } from './plugins'
import { registerRoutes } from './routes'
import { logger } from './utils/logger'

// 创建 Fastify 实例
const fastify = Fastify({
  logger: logger,
  trustProxy: true,
})

// 创建 Prisma 客户端
const prisma = new PrismaClient()

// 声明类型扩展
declare module 'fastify' {
  interface FastifyInstance {
    prisma: PrismaClient
  }
}

// 注册 Prisma 装饰器
fastify.decorate('prisma', prisma)

// 启动服务器
const start = async () => {
  try {
    // 注册插件
    await registerPlugins(fastify)
    
    // 注册路由
    await registerRoutes(fastify)
    
    // 连接数据库
    await prisma.$connect()
    logger.info('Database connected successfully')
    
    // 启动服务器
    await fastify.listen({
      port: config.port,
      host: config.host,
    })
    
    logger.info(`Server is running on http://${config.host}:${config.port}`)
    logger.info(`Swagger documentation available at http://${config.host}:${config.port}/docs`)
    
  } catch (error) {
    logger.error('Error starting server:', error)
    process.exit(1)
  }
}

// 优雅关闭
const gracefulShutdown = async (signal: string) => {
  logger.info(`Received ${signal}, shutting down gracefully`)
  
  try {
    await prisma.$disconnect()
    await fastify.close()
    logger.info('Server closed successfully')
    process.exit(0)
  } catch (error) {
    logger.error('Error during shutdown:', error)
    process.exit(1)
  }
}

// 监听关闭信号
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
process.on('SIGINT', () => gracefulShutdown('SIGINT'))

// 启动应用
start()
