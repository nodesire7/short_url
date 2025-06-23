import { FastifyRequest, FastifyReply } from 'fastify'
import { nanoid } from 'nanoid'
import { config } from '../config'

// 请求类型定义
interface CreateLinkRequest {
  Body: {
    originalUrl: string
    title?: string
    description?: string
    customCode?: string
    domain?: string
    expiresAt?: string
    password?: string
    maxClicks?: number
    tags?: string[]
    isPublic?: boolean
  }
}

interface UpdateLinkRequest {
  Params: { id: string }
  Body: {
    originalUrl?: string
    title?: string
    description?: string
    expiresAt?: string
    password?: string
    maxClicks?: number
    tags?: string[]
    isActive?: boolean
    isPublic?: boolean
  }
}

interface GetLinksRequest {
  Querystring: {
    page?: number
    limit?: number
    search?: string
    tag?: string
    isActive?: boolean
    sortBy?: string
    sortOrder?: 'asc' | 'desc'
  }
}

interface BatchOperationRequest {
  Body: {
    action: 'activate' | 'deactivate' | 'delete'
    linkIds: string[]
  }
}

export const linkController = {
  // 创建短链接
  async create(request: FastifyRequest<CreateLinkRequest>, reply: FastifyReply) {
    try {
      const userId = request.user?.id
      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      const {
        originalUrl,
        title,
        description,
        customCode,
        domain = config.shortLink.defaultDomain,
        expiresAt,
        password,
        maxClicks,
        tags = [],
        isPublic = true,
      } = request.body

      // 验证URL格式
      try {
        new URL(originalUrl)
      } catch {
        return reply.status(400).send({
          success: false,
          message: '请输入有效的URL',
        })
      }

      // 生成短码
      let shortCode = customCode
      if (!shortCode) {
        shortCode = nanoid(config.shortLink.codeLength)
      }

      // 检查短码是否已存在
      const existingLink = await request.server.prisma.link.findUnique({
        where: { shortCode },
      })

      if (existingLink) {
        return reply.status(400).send({
          success: false,
          message: customCode ? '自定义短码已被使用' : '短码生成冲突，请重试',
        })
      }

      // 创建短链接
      const link = await request.server.prisma.link.create({
        data: {
          shortCode,
          originalUrl,
          title,
          description,
          domain,
          userId,
          expiresAt: expiresAt ? new Date(expiresAt) : null,
          password,
          maxClicks,
          tags,
          isPublic,
        },
        include: {
          stats: true,
        },
      })

      // 创建统计记录
      await request.server.prisma.linkStats.create({
        data: {
          linkId: link.id,
        },
      })

      const shortUrl = `http://${domain}/${shortCode}`

      return reply.status(201).send({
        success: true,
        message: '短链接创建成功',
        data: {
          ...link,
          shortUrl,
          totalClicks: 0,
        },
      })
    } catch (error) {
      request.log.error('Create link error:', error)
      return reply.status(500).send({
        success: false,
        message: '创建短链接失败',
      })
    }
  },

  // 获取短链接列表
  async getList(request: FastifyRequest<GetLinksRequest>, reply: FastifyReply) {
    try {
      const userId = request.user?.id
      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      const {
        page = 1,
        limit = 20,
        search,
        tag,
        isActive,
        sortBy = 'createdAt',
        sortOrder = 'desc',
      } = request.query

      const skip = (page - 1) * limit

      // 构建查询条件
      const where: any = { userId }

      if (search) {
        where.OR = [
          { title: { contains: search, mode: 'insensitive' } },
          { originalUrl: { contains: search, mode: 'insensitive' } },
          { shortCode: { contains: search, mode: 'insensitive' } },
        ]
      }

      if (tag) {
        where.tags = { has: tag }
      }

      if (typeof isActive === 'boolean') {
        where.isActive = isActive
      }

      // 获取总数
      const total = await request.server.prisma.link.count({ where })

      // 获取链接列表
      const links = await request.server.prisma.link.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          stats: true,
        },
      })

      // 格式化数据
      const formattedLinks = links.map(link => ({
        id: link.id,
        shortCode: link.shortCode,
        originalUrl: link.originalUrl,
        shortUrl: `http://${link.domain}/${link.shortCode}`,
        title: link.title,
        domain: link.domain,
        isActive: link.isActive,
        totalClicks: link.stats?.totalClicks || 0,
        createdAt: link.createdAt,
      }))

      return reply.send({
        success: true,
        data: {
          links: formattedLinks,
          pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit),
          },
        },
      })
    } catch (error) {
      request.log.error('Get links error:', error)
      return reply.status(500).send({
        success: false,
        message: '获取链接列表失败',
      })
    }
  },

  // 获取单个短链接详情
  async getById(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    try {
      const userId = request.user?.id
      const { id } = request.params

      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      const link = await request.server.prisma.link.findFirst({
        where: {
          id,
          userId,
        },
        include: {
          stats: true,
        },
      })

      if (!link) {
        return reply.status(404).send({
          success: false,
          message: '链接不存在',
        })
      }

      const shortUrl = `http://${link.domain}/${link.shortCode}`

      return reply.send({
        success: true,
        data: {
          ...link,
          shortUrl,
          totalClicks: link.stats?.totalClicks || 0,
          uniqueClicks: link.stats?.uniqueClicks || 0,
          lastClickAt: link.stats?.lastClickAt,
        },
      })
    } catch (error) {
      request.log.error('Get link error:', error)
      return reply.status(500).send({
        success: false,
        message: '获取链接详情失败',
      })
    }
  },

  // 更新短链接
  async update(request: FastifyRequest<UpdateLinkRequest>, reply: FastifyReply) {
    try {
      const userId = request.user?.id
      const { id } = request.params

      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      // 检查链接是否存在且属于当前用户
      const existingLink = await request.server.prisma.link.findFirst({
        where: {
          id,
          userId,
        },
      })

      if (!existingLink) {
        return reply.status(404).send({
          success: false,
          message: '链接不存在',
        })
      }

      // 更新链接
      const updatedLink = await request.server.prisma.link.update({
        where: { id },
        data: {
          ...request.body,
          expiresAt: request.body.expiresAt ? new Date(request.body.expiresAt) : undefined,
          updatedAt: new Date(),
        },
      })

      return reply.send({
        success: true,
        message: '链接更新成功',
        data: updatedLink,
      })
    } catch (error) {
      request.log.error('Update link error:', error)
      return reply.status(500).send({
        success: false,
        message: '更新链接失败',
      })
    }
  },

  // 删除短链接
  async delete(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    try {
      const userId = request.user?.id
      const { id } = request.params

      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      // 检查链接是否存在且属于当前用户
      const existingLink = await request.server.prisma.link.findFirst({
        where: {
          id,
          userId,
        },
      })

      if (!existingLink) {
        return reply.status(404).send({
          success: false,
          message: '链接不存在',
        })
      }

      // 删除链接（级联删除相关数据）
      await request.server.prisma.link.delete({
        where: { id },
      })

      return reply.send({
        success: true,
        message: '链接删除成功',
      })
    } catch (error) {
      request.log.error('Delete link error:', error)
      return reply.status(500).send({
        success: false,
        message: '删除链接失败',
      })
    }
  },

  // 批量操作
  async batchOperation(request: FastifyRequest<BatchOperationRequest>, reply: FastifyReply) {
    try {
      const userId = request.user?.id
      const { action, linkIds } = request.body

      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      let result
      let message = ''

      switch (action) {
        case 'activate':
          result = await request.server.prisma.link.updateMany({
            where: {
              id: { in: linkIds },
              userId,
            },
            data: { isActive: true },
          })
          message = `成功激活 ${result.count} 个链接`
          break

        case 'deactivate':
          result = await request.server.prisma.link.updateMany({
            where: {
              id: { in: linkIds },
              userId,
            },
            data: { isActive: false },
          })
          message = `成功停用 ${result.count} 个链接`
          break

        case 'delete':
          result = await request.server.prisma.link.deleteMany({
            where: {
              id: { in: linkIds },
              userId,
            },
          })
          message = `成功删除 ${result.count} 个链接`
          break

        default:
          return reply.status(400).send({
            success: false,
            message: '无效的操作类型',
          })
      }

      return reply.send({
        success: true,
        message,
        data: {
          affected: result.count,
        },
      })
    } catch (error) {
      request.log.error('Batch operation error:', error)
      return reply.status(500).send({
        success: false,
        message: '批量操作失败',
      })
    }
  },
}
