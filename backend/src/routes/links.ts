import { FastifyInstance } from 'fastify'
import { linkController } from '../controllers/links'

export async function linkRoutes(fastify: FastifyInstance) {
  // 创建短链接
  fastify.post('/', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '创建短链接',
      tags: ['短链接'],
      security: [{ Bearer: [] }],
      body: {
        type: 'object',
        required: ['originalUrl'],
        properties: {
          originalUrl: { type: 'string', format: 'uri' },
          title: { type: 'string', maxLength: 200 },
          description: { type: 'string', maxLength: 500 },
          customCode: { type: 'string', minLength: 3, maxLength: 20 },
          domain: { type: 'string' },
          expiresAt: { type: 'string', format: 'date-time' },
          password: { type: 'string', maxLength: 100 },
          maxClicks: { type: 'integer', minimum: 1 },
          tags: { type: 'array', items: { type: 'string' } },
          isPublic: { type: 'boolean' },
        },
      },
      response: {
        201: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                shortCode: { type: 'string' },
                originalUrl: { type: 'string' },
                shortUrl: { type: 'string' },
                title: { type: 'string' },
                description: { type: 'string' },
                domain: { type: 'string' },
                isActive: { type: 'boolean' },
                isPublic: { type: 'boolean' },
                expiresAt: { type: 'string' },
                tags: { type: 'array', items: { type: 'string' } },
                createdAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, linkController.create)

  // 获取用户的短链接列表
  fastify.get('/', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '获取用户的短链接列表',
      tags: ['短链接'],
      security: [{ Bearer: [] }],
      querystring: {
        type: 'object',
        properties: {
          page: { type: 'integer', minimum: 1, default: 1 },
          limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
          search: { type: 'string' },
          tag: { type: 'string' },
          isActive: { type: 'boolean' },
          sortBy: { type: 'string', enum: ['createdAt', 'updatedAt', 'clicks'] },
          sortOrder: { type: 'string', enum: ['asc', 'desc'], default: 'desc' },
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
                links: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'string' },
                      shortCode: { type: 'string' },
                      originalUrl: { type: 'string' },
                      shortUrl: { type: 'string' },
                      title: { type: 'string' },
                      domain: { type: 'string' },
                      isActive: { type: 'boolean' },
                      totalClicks: { type: 'integer' },
                      createdAt: { type: 'string' },
                    },
                  },
                },
                pagination: {
                  type: 'object',
                  properties: {
                    page: { type: 'integer' },
                    limit: { type: 'integer' },
                    total: { type: 'integer' },
                    pages: { type: 'integer' },
                  },
                },
              },
            },
          },
        },
      },
    },
  }, linkController.getList)

  // 获取单个短链接详情
  fastify.get('/:id', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '获取短链接详情',
      tags: ['短链接'],
      security: [{ Bearer: [] }],
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string' },
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
                id: { type: 'string' },
                shortCode: { type: 'string' },
                originalUrl: { type: 'string' },
                shortUrl: { type: 'string' },
                title: { type: 'string' },
                description: { type: 'string' },
                domain: { type: 'string' },
                isActive: { type: 'boolean' },
                isPublic: { type: 'boolean' },
                expiresAt: { type: 'string' },
                maxClicks: { type: 'integer' },
                tags: { type: 'array', items: { type: 'string' } },
                totalClicks: { type: 'integer' },
                uniqueClicks: { type: 'integer' },
                lastClickAt: { type: 'string' },
                createdAt: { type: 'string' },
                updatedAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, linkController.getById)

  // 更新短链接
  fastify.put('/:id', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '更新短链接',
      tags: ['短链接'],
      security: [{ Bearer: [] }],
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string' },
        },
      },
      body: {
        type: 'object',
        properties: {
          originalUrl: { type: 'string', format: 'uri' },
          title: { type: 'string', maxLength: 200 },
          description: { type: 'string', maxLength: 500 },
          expiresAt: { type: 'string', format: 'date-time' },
          password: { type: 'string', maxLength: 100 },
          maxClicks: { type: 'integer', minimum: 1 },
          tags: { type: 'array', items: { type: 'string' } },
          isActive: { type: 'boolean' },
          isPublic: { type: 'boolean' },
        },
      },
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                shortCode: { type: 'string' },
                originalUrl: { type: 'string' },
                title: { type: 'string' },
                isActive: { type: 'boolean' },
                updatedAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, linkController.update)

  // 删除短链接
  fastify.delete('/:id', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '删除短链接',
      tags: ['短链接'],
      security: [{ Bearer: [] }],
      params: {
        type: 'object',
        required: ['id'],
        properties: {
          id: { type: 'string' },
        },
      },
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
          },
        },
      },
    },
  }, linkController.delete)

  // 批量操作
  fastify.post('/batch', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '批量操作短链接',
      tags: ['短链接'],
      security: [{ Bearer: [] }],
      body: {
        type: 'object',
        required: ['action', 'linkIds'],
        properties: {
          action: { type: 'string', enum: ['activate', 'deactivate', 'delete'] },
          linkIds: { type: 'array', items: { type: 'string' }, minItems: 1 },
        },
      },
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            data: {
              type: 'object',
              properties: {
                affected: { type: 'integer' },
              },
            },
          },
        },
      },
    },
  }, linkController.batchOperation)
}
