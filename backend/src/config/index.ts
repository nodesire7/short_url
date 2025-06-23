import { z } from 'zod'

// 环境变量验证模式
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().transform(Number).default('3000'),
  HOST: z.string().default('0.0.0.0'),
  
  // 数据库配置
  DATABASE_URL: z.string(),
  
  // Redis 配置
  REDIS_URL: z.string(),
  
  // JWT 配置
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('7d'),
  
  // CORS 配置
  CORS_ORIGIN: z.string().default('*'),
  
  // 限流配置
  RATE_LIMIT_MAX: z.string().transform(Number).default('100'),
  RATE_LIMIT_WINDOW: z.string().transform(Number).default('900000'), // 15分钟
  
  // 短链接配置
  DEFAULT_DOMAIN: z.string().default('localhost:3000'),
  SHORT_CODE_LENGTH: z.string().transform(Number).default('6'),
  
  // 文件上传配置
  MAX_FILE_SIZE: z.string().transform(Number).default('5242880'), // 5MB
  
  // 邮件配置（可选）
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.string().transform(Number).optional(),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  
  // 分析配置
  ENABLE_ANALYTICS: z.string().transform(Boolean).default('true'),
  
  // 日志配置
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
})

// 验证环境变量
const env = envSchema.parse(process.env)

// 导出配置
export const config = {
  // 基本配置
  nodeEnv: env.NODE_ENV,
  port: env.PORT,
  host: env.HOST,
  isDevelopment: env.NODE_ENV === 'development',
  isProduction: env.NODE_ENV === 'production',
  
  // 数据库配置
  database: {
    url: env.DATABASE_URL,
  },
  
  // Redis 配置
  redis: {
    url: env.REDIS_URL,
  },
  
  // JWT 配置
  jwt: {
    secret: env.JWT_SECRET,
    expiresIn: env.JWT_EXPIRES_IN,
  },
  
  // CORS 配置
  cors: {
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','),
  },
  
  // 限流配置
  rateLimit: {
    max: env.RATE_LIMIT_MAX,
    timeWindow: env.RATE_LIMIT_WINDOW,
  },
  
  // 短链接配置
  shortLink: {
    defaultDomain: env.DEFAULT_DOMAIN,
    codeLength: env.SHORT_CODE_LENGTH,
  },
  
  // 文件配置
  file: {
    maxSize: env.MAX_FILE_SIZE,
  },
  
  // 邮件配置
  smtp: {
    host: env.SMTP_HOST,
    port: env.SMTP_PORT,
    user: env.SMTP_USER,
    pass: env.SMTP_PASS,
  },
  
  // 功能开关
  features: {
    analytics: env.ENABLE_ANALYTICS,
  },
  
  // 日志配置
  log: {
    level: env.LOG_LEVEL,
  },
} as const

export type Config = typeof config
