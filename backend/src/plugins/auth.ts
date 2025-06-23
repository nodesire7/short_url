import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify'
import fp from 'fastify-plugin'

// 认证中间件
async function authPlugin(fastify: FastifyInstance) {
  // 注册认证装饰器
  fastify.decorate('authenticate', async function (request: FastifyRequest, reply: FastifyReply) {
    try {
      // 验证JWT令牌
      await request.jwtVerify()
    } catch (err) {
      reply.status(401).send({
        success: false,
        message: '未授权访问，请先登录',
      })
    }
  })

  // 管理员权限检查
  fastify.decorate('requireAdmin', async function (request: FastifyRequest, reply: FastifyReply) {
    try {
      await request.jwtVerify()
      
      if (request.user?.role !== 'ADMIN' && request.user?.role !== 'SUPER_ADMIN') {
        reply.status(403).send({
          success: false,
          message: '需要管理员权限',
        })
      }
    } catch (err) {
      reply.status(401).send({
        success: false,
        message: '未授权访问，请先登录',
      })
    }
  })

  // 超级管理员权限检查
  fastify.decorate('requireSuperAdmin', async function (request: FastifyRequest, reply: FastifyReply) {
    try {
      await request.jwtVerify()
      
      if (request.user?.role !== 'SUPER_ADMIN') {
        reply.status(403).send({
          success: false,
          message: '需要超级管理员权限',
        })
      }
    } catch (err) {
      reply.status(401).send({
        success: false,
        message: '未授权访问，请先登录',
      })
    }
  })
}

// 扩展 Fastify 类型
declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>
    requireAdmin: (request: FastifyRequest, reply: FastifyReply) => Promise<void>
    requireSuperAdmin: (request: FastifyRequest, reply: FastifyReply) => Promise<void>
  }
}

export default fp(authPlugin)
