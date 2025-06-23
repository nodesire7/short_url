import { FastifyRequest, FastifyReply } from 'fastify'
import bcrypt from 'bcryptjs'
import { z } from 'zod'
import { PrismaClient } from '@prisma/client'

// 请求类型定义
interface RegisterRequest {
  Body: {
    email: string
    username: string
    password: string
  }
}

interface LoginRequest {
  Body: {
    email: string
    password: string
  }
}

interface ChangePasswordRequest {
  Body: {
    currentPassword: string
    newPassword: string
  }
}



export const authController = {
  // 用户注册
  async register(request: FastifyRequest<RegisterRequest>, reply: FastifyReply) {
    try {
      const { email, username, password } = request.body

      // 检查用户是否已存在
      const existingUser = await request.server.prisma.user.findFirst({
        where: {
          OR: [
            { email },
            { username },
          ],
        },
      })

      if (existingUser) {
        return reply.status(400).send({
          success: false,
          message: existingUser.email === email ? '邮箱已被注册' : '用户名已被使用',
        })
      }

      // 加密密码
      const hashedPassword = await bcrypt.hash(password, 12)

      // 创建用户
      const user = await request.server.prisma.user.create({
        data: {
          email,
          username,
          password: hashedPassword,
        },
        select: {
          id: true,
          email: true,
          username: true,
          role: true,
          isActive: true,
          createdAt: true,
        },
      })

      // 生成 JWT 令牌
      const token = request.server.jwt.sign({
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
      })

      return reply.status(201).send({
        success: true,
        message: '注册成功',
        data: {
          user,
          token,
        },
      })
    } catch (error) {
      request.log.error('Registration error:', error)
      return reply.status(500).send({
        success: false,
        message: '注册失败，请稍后重试',
      })
    }
  },

  // 用户登录
  async login(request: FastifyRequest<LoginRequest>, reply: FastifyReply) {
    try {
      const { email, password } = request.body

      // 查找用户
      const user = await request.server.prisma.user.findUnique({
        where: { email },
      })

      if (!user) {
        return reply.status(401).send({
          success: false,
          message: '邮箱或密码错误',
        })
      }

      // 检查用户是否激活
      if (!user.isActive) {
        return reply.status(401).send({
          success: false,
          message: '账户已被禁用',
        })
      }

      // 验证密码
      const isValidPassword = await bcrypt.compare(password, user.password)
      if (!isValidPassword) {
        return reply.status(401).send({
          success: false,
          message: '邮箱或密码错误',
        })
      }

      // 生成 JWT 令牌
      const token = request.server.jwt.sign({
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
      })

      return reply.send({
        success: true,
        message: '登录成功',
        data: {
          user: {
            id: user.id,
            email: user.email,
            username: user.username,
            role: user.role,
          },
          token,
        },
      })
    } catch (error) {
      request.log.error('Login error:', error)
      return reply.status(500).send({
        success: false,
        message: '登录失败，请稍后重试',
      })
    }
  },

  // 获取当前用户信息
  async getMe(request: FastifyRequest, reply: FastifyReply) {
    try {
      const userId = request.user?.id

      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      const user = await request.server.prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          email: true,
          username: true,
          role: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
        },
      })

      if (!user) {
        return reply.status(404).send({
          success: false,
          message: '用户不存在',
        })
      }

      return reply.send({
        success: true,
        data: user,
      })
    } catch (error) {
      request.log.error('Get user error:', error)
      return reply.status(500).send({
        success: false,
        message: '获取用户信息失败',
      })
    }
  },

  // 修改密码
  async changePassword(request: FastifyRequest<ChangePasswordRequest>, reply: FastifyReply) {
    try {
      const userId = request.user?.id
      const { currentPassword, newPassword } = request.body

      if (!userId) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      // 获取用户当前密码
      const user = await request.server.prisma.user.findUnique({
        where: { id: userId },
        select: { password: true },
      })

      if (!user) {
        return reply.status(404).send({
          success: false,
          message: '用户不存在',
        })
      }

      // 验证当前密码
      const isValidPassword = await bcrypt.compare(currentPassword, user.password)
      if (!isValidPassword) {
        return reply.status(400).send({
          success: false,
          message: '当前密码错误',
        })
      }

      // 加密新密码
      const hashedNewPassword = await bcrypt.hash(newPassword, 12)

      // 更新密码
      await request.server.prisma.user.update({
        where: { id: userId },
        data: { password: hashedNewPassword },
      })

      return reply.send({
        success: true,
        message: '密码修改成功',
      })
    } catch (error) {
      request.log.error('Change password error:', error)
      return reply.status(500).send({
        success: false,
        message: '密码修改失败',
      })
    }
  },

  // 刷新令牌
  async refreshToken(request: FastifyRequest, reply: FastifyReply) {
    try {
      const user = request.user

      if (!user) {
        return reply.status(401).send({
          success: false,
          message: '未授权访问',
        })
      }

      // 生成新的 JWT 令牌
      const token = request.server.jwt.sign({
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
      })

      return reply.send({
        success: true,
        data: { token },
      })
    } catch (error) {
      request.log.error('Refresh token error:', error)
      return reply.status(500).send({
        success: false,
        message: '令牌刷新失败',
      })
    }
  },
}
