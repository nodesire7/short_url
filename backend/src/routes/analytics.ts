import { FastifyInstance } from 'fastify'

export async function analyticsRoutes(fastify: FastifyInstance) {
  // 获取链接分析数据
  fastify.get('/links/:id', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '获取链接分析数据',
      tags: ['分析'],
      security: [{ Bearer: [] }],
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string' },
        },
      },
      querystring: {
        type: 'object',
        properties: {
          period: { type: 'string', enum: ['7d', '30d', '90d'], default: '7d' },
        },
      },
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            data: {
              type: 'object',
              properties: {
                overview: {
                  type: 'object',
                  properties: {
                    totalClicks: { type: 'integer' },
                    uniqueClicks: { type: 'integer' },
                    clicksToday: { type: 'integer' },
                    avgClicksPerDay: { type: 'number' },
                  },
                },
                timeline: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      date: { type: 'string' },
                      clicks: { type: 'integer' },
                    },
                  },
                },
                countries: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      country: { type: 'string' },
                      clicks: { type: 'integer' },
                    },
                  },
                },
                devices: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      device: { type: 'string' },
                      clicks: { type: 'integer' },
                    },
                  },
                },
                browsers: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      browser: { type: 'string' },
                      clicks: { type: 'integer' },
                    },
                  },
                },
                referrers: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      referrer: { type: 'string' },
                      clicks: { type: 'integer' },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  }, async (request, reply) => {
    try {
      const userId = request.user?.id
      const { id } = request.params as { id: string }
      const { period = '7d' } = request.query as { period?: string }

      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      // 检查链接是否属于当前用户
      const link = await request.server.prisma.link.findFirst({
        where: { id, userId },
        include: { stats: true },
      })

      if (!link) {
        return reply.status(404).send({
          success: false,
          message: '链接不存在',
        })
      }

      // 计算时间范围
      const days = period === '7d' ? 7 : period === '30d' ? 30 : 90
      const startDate = new Date()
      startDate.setDate(startDate.getDate() - days)

      // 获取今天的点击数
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      const tomorrow = new Date(today)
      tomorrow.setDate(tomorrow.getDate() + 1)

      const [clicksToday, timelineData, countryData, deviceData, browserData, referrerData] = await Promise.all([
        // 今天的点击数
        request.server.prisma.click.count({
          where: {
            linkId: id,
            createdAt: { gte: today, lt: tomorrow },
          },
        }),

        // 时间线数据
        request.server.prisma.$queryRaw`
          SELECT DATE(created_at) as date, COUNT(*) as clicks
          FROM clicks
          WHERE link_id = ${id} AND created_at >= ${startDate}
          GROUP BY DATE(created_at)
          ORDER BY date
        `,

        // 国家统计
        request.server.prisma.click.groupBy({
          by: ['country'],
          where: {
            linkId: id,
            createdAt: { gte: startDate },
            country: { not: null },
          },
          _count: true,
          orderBy: { _count: { country: 'desc' } },
          take: 10,
        }),

        // 设备统计
        request.server.prisma.click.groupBy({
          by: ['device'],
          where: {
            linkId: id,
            createdAt: { gte: startDate },
            device: { not: null },
          },
          _count: true,
          orderBy: { _count: { device: 'desc' } },
        }),

        // 浏览器统计
        request.server.prisma.click.groupBy({
          by: ['browser'],
          where: {
            linkId: id,
            createdAt: { gte: startDate },
            browser: { not: null },
          },
          _count: true,
          orderBy: { _count: { browser: 'desc' } },
          take: 10,
        }),

        // 来源统计
        request.server.prisma.click.groupBy({
          by: ['referer'],
          where: {
            linkId: id,
            createdAt: { gte: startDate },
            referer: { not: null },
          },
          _count: true,
          orderBy: { _count: { referer: 'desc' } },
          take: 10,
        }),
      ])

      // 计算平均每日点击数
      const totalClicks = link.stats?.totalClicks || 0
      const avgClicksPerDay = totalClicks / Math.max(1, Math.ceil((new Date().getTime() - link.createdAt.getTime()) / (1000 * 60 * 60 * 24)))

      return reply.send({
        success: true,
        data: {
          overview: {
            totalClicks,
            uniqueClicks: link.stats?.uniqueClicks || 0,
            clicksToday,
            avgClicksPerDay: Math.round(avgClicksPerDay * 100) / 100,
          },
          timeline: timelineData,
          countries: countryData.map(item => ({
            country: item.country || 'Unknown',
            clicks: item._count,
          })),
          devices: deviceData.map(item => ({
            device: item.device || 'Unknown',
            clicks: item._count,
          })),
          browsers: browserData.map(item => ({
            browser: item.browser || 'Unknown',
            clicks: item._count,
          })),
          referrers: referrerData.map(item => ({
            referrer: item.referer || 'Direct',
            clicks: item._count,
          })),
        },
      })
    } catch (error) {
      request.log.error('Get analytics error:', error)
      return reply.status(500).send({
        success: false,
        message: '获取分析数据失败',
      })
    }
  })
}
