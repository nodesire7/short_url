import { FastifyInstance } from 'fastify'
import { authRoutes } from './auth'
import { linkRoutes } from './links'
import { userRoutes } from './users'
import { analyticsRoutes } from './analytics'
import { redirectRoutes } from './redirect'
import { healthRoutes } from './health'

export async function registerRoutes(fastify: FastifyInstance) {
  // 健康检查路由（无前缀）
  await fastify.register(healthRoutes)

  // API 路由前缀
  await fastify.register(async function (fastify) {
    // 健康检查路由
    await fastify.register(healthRoutes, { prefix: '/health' })

    // 认证路由
    await fastify.register(authRoutes, { prefix: '/auth' })

    // 用户路由
    await fastify.register(userRoutes, { prefix: '/users' })

    // 链接路由
    await fastify.register(linkRoutes, { prefix: '/links' })

    // 分析路由
    await fastify.register(analyticsRoutes, { prefix: '/analytics' })
  }, { prefix: '/api/v1' })

  // 短链接重定向路由（无前缀）
  await fastify.register(redirectRoutes)
}
