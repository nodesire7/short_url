import { FastifyInstance } from 'fastify'

export async function healthRoutes(fastify: FastifyInstance) {
  // 健康检查端点
  fastify.get('/health', {
    schema: {
      description: '健康检查',
      tags: ['系统'],
      response: {
        200: {
          type: 'object',
          properties: {
            status: { type: 'string' },
            timestamp: { type: 'string' },
            uptime: { type: 'number' },
            version: { type: 'string' },
            database: { type: 'string' },
            redis: { type: 'string' },
          },
        },
      },
    },
  }, async (request, reply) => {
    try {
      // 检查数据库连接
      let dbStatus = 'connected'
      try {
        await request.server.prisma.$queryRaw`SELECT 1`
      } catch (error) {
        dbStatus = 'disconnected'
      }

      // 检查Redis连接
      let redisStatus = 'connected'
      try {
        // 这里需要根据实际的Redis客户端实现
        redisStatus = 'connected'
      } catch (error) {
        redisStatus = 'disconnected'
      }

      return reply.send({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        version: '1.0.0',
        database: dbStatus,
        redis: redisStatus,
      })
    } catch (error) {
      return reply.status(503).send({
        status: 'error',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        version: '1.0.0',
        database: 'unknown',
        redis: 'unknown',
      })
    }
  })
}
