import { FastifyRequest, FastifyReply } from 'fastify'
import bcrypt from 'bcryptjs'

interface RedirectRequest {
  Params: { shortCode: string }
  Querystring: { password?: string }
}

interface PreviewRequest {
  Params: { shortCode: string }
}

// 解析User-Agent
function parseUserAgent(userAgent: string) {
  const device = /Mobile|Android|iPhone|iPad/.test(userAgent) ? 'mobile' : 'desktop'
  
  let browser = 'unknown'
  if (userAgent.includes('Chrome')) browser = 'Chrome'
  else if (userAgent.includes('Firefox')) browser = 'Firefox'
  else if (userAgent.includes('Safari')) browser = 'Safari'
  else if (userAgent.includes('Edge')) browser = 'Edge'
  
  let os = 'unknown'
  if (userAgent.includes('Windows')) os = 'Windows'
  else if (userAgent.includes('Mac')) os = 'macOS'
  else if (userAgent.includes('Linux')) os = 'Linux'
  else if (userAgent.includes('Android')) os = 'Android'
  else if (userAgent.includes('iOS')) os = 'iOS'
  
  return { device, browser, os }
}

// 获取客户端IP
function getClientIP(request: FastifyRequest): string {
  const forwarded = request.headers['x-forwarded-for']
  const realIP = request.headers['x-real-ip']
  
  if (typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim()
  }
  
  if (typeof realIP === 'string') {
    return realIP
  }
  
  return request.ip || 'unknown'
}

export const redirectController = {
  // 短链接重定向
  async redirect(request: FastifyRequest<RedirectRequest>, reply: FastifyReply) {
    try {
      const { shortCode } = request.params
      const { password } = request.query

      // 查找短链接
      const link = await request.server.prisma.link.findUnique({
        where: { shortCode },
        include: {
          stats: true,
        },
      })

      if (!link) {
        return reply.status(404).send({
          success: false,
          message: '短链接不存在',
        })
      }

      // 检查链接是否激活
      if (!link.isActive) {
        return reply.status(404).send({
          success: false,
          message: '短链接已被禁用',
        })
      }

      // 检查是否过期
      if (link.expiresAt && new Date() > link.expiresAt) {
        return reply.status(410).send({
          success: false,
          message: '短链接已过期',
        })
      }

      // 检查最大点击次数
      if (link.maxClicks && link.stats && link.stats.totalClicks >= link.maxClicks) {
        return reply.status(410).send({
          success: false,
          message: '短链接已达到最大访问次数',
        })
      }

      // 检查密码保护
      if (link.password) {
        if (!password) {
          return reply.status(401).send({
            success: false,
            message: '需要密码访问',
            requiresPassword: true,
          })
        }

        const isValidPassword = await bcrypt.compare(password, link.password)
        if (!isValidPassword) {
          return reply.status(401).send({
            success: false,
            message: '密码错误',
            requiresPassword: true,
          })
        }
      }

      // 记录访问统计
      const ip = getClientIP(request)
      const userAgent = request.headers['user-agent'] || ''
      const referer = request.headers.referer || null
      const { device, browser, os } = parseUserAgent(userAgent)

      // 异步记录点击数据，不阻塞重定向
      setImmediate(async () => {
        try {
          // 创建点击记录
          await request.server.prisma.click.create({
            data: {
              linkId: link.id,
              ip,
              userAgent,
              referer,
              device,
              browser,
              os,
            },
          })

          // 检查是否为唯一访问（基于IP）
          const existingClick = await request.server.prisma.click.findFirst({
            where: {
              linkId: link.id,
              ip,
            },
            orderBy: {
              createdAt: 'asc',
            },
          })

          const isUniqueClick = !existingClick || existingClick.createdAt.getTime() === new Date().getTime()

          // 更新统计数据
          await request.server.prisma.linkStats.update({
            where: { linkId: link.id },
            data: {
              totalClicks: { increment: 1 },
              uniqueClicks: isUniqueClick ? { increment: 1 } : undefined,
              lastClickAt: new Date(),
            },
          })

          // 缓存统计数据到Redis
          const cacheKey = `link_stats:${link.id}`
          await request.server.redis.setex(cacheKey, 300, JSON.stringify({
            totalClicks: (link.stats?.totalClicks || 0) + 1,
            uniqueClicks: (link.stats?.uniqueClicks || 0) + (isUniqueClick ? 1 : 0),
            lastClickAt: new Date(),
          }))
        } catch (error) {
          request.log.error('Error recording click:', error)
        }
      })

      // 执行重定向
      return reply.redirect(302, link.originalUrl)
    } catch (error) {
      request.log.error('Redirect error:', error)
      return reply.status(500).send({
        success: false,
        message: '重定向失败',
      })
    }
  },

  // 短链接预览
  async preview(request: FastifyRequest<PreviewRequest>, reply: FastifyReply) {
    try {
      const { shortCode } = request.params

      // 查找短链接
      const link = await request.server.prisma.link.findUnique({
        where: { shortCode },
        include: {
          stats: true,
        },
      })

      if (!link) {
        return reply.status(404).send({
          success: false,
          message: '短链接不存在',
        })
      }

      // 只返回公开信息
      return reply.send({
        success: true,
        data: {
          shortCode: link.shortCode,
          originalUrl: link.originalUrl,
          title: link.title,
          description: link.description,
          domain: link.domain,
          isActive: link.isActive,
          requiresPassword: !!link.password,
          totalClicks: link.stats?.totalClicks || 0,
          createdAt: link.createdAt,
        },
      })
    } catch (error) {
      request.log.error('Preview error:', error)
      return reply.status(500).send({
        success: false,
        message: '获取预览信息失败',
      })
    }
  },
}
