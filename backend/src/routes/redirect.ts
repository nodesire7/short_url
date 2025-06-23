import { FastifyInstance } from 'fastify'
import { redirectController } from '../controllers/redirect'

export async function redirectRoutes(fastify: FastifyInstance) {
  // 短链接重定向
  fastify.get('/:shortCode', {
    schema: {
      description: '短链接重定向',
      tags: ['重定向'],
      params: {
        type: 'object',
        required: ['shortCode'],
        properties: {
          shortCode: { type: 'string' },
        },
      },
      querystring: {
        type: 'object',
        properties: {
          password: { type: 'string' },
        },
      },
      response: {
        302: {
          description: '重定向到目标URL',
        },
        404: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
          },
        },
      },
    },
  }, redirectController.redirect)

  // 短链接预览
  fastify.get('/:shortCode/preview', {
    schema: {
      description: '短链接预览信息',
      tags: ['重定向'],
      params: {
        type: 'object',
        required: ['shortCode'],
        properties: {
          shortCode: { type: 'string' },
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
                shortCode: { type: 'string' },
                originalUrl: { type: 'string' },
                title: { type: 'string' },
                description: { type: 'string' },
                domain: { type: 'string' },
                isActive: { type: 'boolean' },
                requiresPassword: { type: 'boolean' },
                totalClicks: { type: 'integer' },
                createdAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, redirectController.preview)
}
