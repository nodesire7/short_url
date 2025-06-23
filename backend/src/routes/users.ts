import { FastifyInstance } from 'fastify'

export async function userRoutes(fastify: FastifyInstance) {
  // 获取用户统计信息
  fastify.get('/stats', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '获取用户统计信息',
      tags: ['用户'],
      security: [{ Bearer: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            data: {
              type: 'object',
              properties: {
                totalLinks: { type: 'integer' },
                activeLinks: { type: 'integer' },
                totalClicks: { type: 'integer' },
                uniqueClicks: { type: 'integer' },
                recentClicks: { type: 'integer' },
              },
            },
          },
        },
      },
    },
  }, async (request, reply) => {
    try {
      const userId = request.user?.id
      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      // 获取用户链接统计
      const [totalLinks, activeLinks, clickStats] = await Promise.all([
        request.server.prisma.link.count({
          where: { userId },
        }),
        request.server.prisma.link.count({
          where: { userId, isActive: true },
        }),
        request.server.prisma.linkStats.aggregate({
          where: {
            link: { userId },
          },
          _sum: {
            totalClicks: true,
            uniqueClicks: true,
          },
        }),
      ])

      // 获取最近7天的点击数
      const sevenDaysAgo = new Date()
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

      const recentClicks = await request.server.prisma.click.count({
        where: {
          link: { userId },
          createdAt: { gte: sevenDaysAgo },
        },
      })

      return reply.send({
        success: true,
        data: {
          totalLinks,
          activeLinks,
          totalClicks: clickStats._sum.totalClicks || 0,
          uniqueClicks: clickStats._sum.uniqueClicks || 0,
          recentClicks,
        },
      })
    } catch (error) {
      request.log.error('Get user stats error:', error)
      return reply.status(500).send({
        success: false,
        message: '获取统计信息失败',
      })
    }
  })
}
