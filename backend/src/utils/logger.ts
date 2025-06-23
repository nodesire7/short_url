import pino from 'pino'
import { config } from '../config'

// 创建日志器
export const logger = pino({
  level: config.log.level,
  transport: config.isDevelopment
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
  formatters: {
    level: (label) => {
      return { level: label }
    },
  },
  timestamp: pino.stdTimeFunctions.isoTime,
})

// 导出类型化的日志器
export type Logger = typeof logger
