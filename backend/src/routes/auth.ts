import { FastifyInstance } from 'fastify'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { authController } from '../controllers/auth'

// 请求验证模式
const registerSchema = z.object({
  email: z.string().email('请输入有效的邮箱地址'),
  username: z.string().min(3, '用户名至少3个字符').max(20, '用户名最多20个字符'),
  password: z.string().min(6, '密码至少6个字符').max(100, '密码最多100个字符'),
})

const loginSchema = z.object({
  email: z.string().email('请输入有效的邮箱地址'),
  password: z.string().min(1, '请输入密码'),
})

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, '请输入当前密码'),
  newPassword: z.string().min(6, '新密码至少6个字符').max(100, '新密码最多100个字符'),
})

export async function authRoutes(fastify: FastifyInstance) {
  // 用户注册
  fastify.post('/register', {
    schema: {
      description: '用户注册',
      tags: ['认证'],
      body: {
        type: 'object',
        required: ['email', 'username', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          username: { type: 'string', minLength: 3, maxLength: 20 },
          password: { type: 'string', minLength: 6, maxLength: 100 },
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
                user: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    email: { type: 'string' },
                    username: { type: 'string' },
                    role: { type: 'string' },
                  },
                },
                token: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, authController.register)

  // 用户登录
  fastify.post('/login', {
    schema: {
      description: '用户登录',
      tags: ['认证'],
      body: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string' },
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
                user: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    email: { type: 'string' },
                    username: { type: 'string' },
                    role: { type: 'string' },
                  },
                },
                token: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, authController.login)

  // 获取当前用户信息
  fastify.get('/me', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '获取当前用户信息',
      tags: ['认证'],
      security: [{ Bearer: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                email: { type: 'string' },
                username: { type: 'string' },
                role: { type: 'string' },
                isActive: { type: 'boolean' },
                createdAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, authController.getMe)

  // 修改密码
  fastify.put('/change-password', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '修改密码',
      tags: ['认证'],
      security: [{ Bearer: [] }],
      body: {
        type: 'object',
        required: ['currentPassword', 'newPassword'],
        properties: {
          currentPassword: { type: 'string' },
          newPassword: { type: 'string', minLength: 6, maxLength: 100 },
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
  }, authController.changePassword)

  // 刷新令牌
  fastify.post('/refresh', {
    preHandler: [fastify.authenticate],
    schema: {
      description: '刷新访问令牌',
      tags: ['认证'],
      security: [{ Bearer: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            data: {
              type: 'object',
              properties: {
                token: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, authController.refreshToken)
}
