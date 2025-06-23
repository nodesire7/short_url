import { FastifyInstance } from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import rateLimit from '@fastify/rate-limit'
import jwt from '@fastify/jwt'
import redis from '@fastify/redis'
import swagger from '@fastify/swagger'
import swaggerUi from '@fastify/swagger-ui'
import authPlugin from './auth'
import { config } from '../config'

export async function registerPlugins(fastify: FastifyInstance) {
  // 安全头
  await fastify.register(helmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
  })

  // CORS
  await fastify.register(cors, {
    origin: config.cors.origin,
    credentials: true,
  })

  // Redis
  await fastify.register(redis, {
    url: config.redis.url,
  })

  // JWT
  await fastify.register(jwt, {
    secret: config.jwt.secret,
  })

  // 认证插件
  await fastify.register(authPlugin)

  // 限流
  await fastify.register(rateLimit, {
    max: config.rateLimit.max,
    timeWindow: config.rateLimit.timeWindow,
    redis: fastify.redis,
  })

  // Swagger 文档
  await fastify.register(swagger, {
    swagger: {
      info: {
        title: 'Modern ShortLink API',
        description: '现代化短链接系统 API 文档',
        version: '1.0.0',
      },
      host: `${config.host}:${config.port}`,
      schemes: ['http', 'https'],
      consumes: ['application/json'],
      produces: ['application/json'],
      securityDefinitions: {
        Bearer: {
          type: 'apiKey',
          name: 'Authorization',
          in: 'header',
          description: 'JWT token with Bearer prefix',
        },
      },
    },
  })

  await fastify.register(swaggerUi, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'full',
      deepLinking: false,
    },
    staticCSP: true,
    transformStaticCSP: (header) => header,
  })

  // 健康检查
  fastify.get('/health', async () => {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: config.nodeEnv,
    }
  })
}
