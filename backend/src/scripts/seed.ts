import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 开始数据库种子数据初始化...')

  try {
    // 创建系统设置
    const systemSettings = await prisma.systemSettings.upsert({
      where: { id: 'system' },
      update: {},
      create: {
        id: 'system',
        siteName: 'Modern ShortLink',
        siteDescription: '现代化短链接系统',
        defaultDomain: 'localhost:3000',
        allowRegistration: true,
        requireEmailVerification: false,
        maxLinksPerUser: 1000,
        enableAnalytics: true,
        enableRateLimit: true,
        rateLimitMax: 100,
        rateLimitWindow: 900000,
      },
    })
    console.log('✅ 系统设置创建完成')

    // 创建超级管理员用户
    const adminPassword = await bcrypt.hash('admin123456', 12)
    const adminUser = await prisma.user.upsert({
      where: { email: 'admin@shortlink.com' },
      update: {},
      create: {
        email: 'admin@shortlink.com',
        username: 'admin',
        password: adminPassword,
        role: 'SUPER_ADMIN',
        isActive: true,
      },
    })
    console.log('✅ 超级管理员用户创建完成')
    console.log('   邮箱: admin@shortlink.com')
    console.log('   密码: admin123456')

    // 创建测试用户
    const testPassword = await bcrypt.hash('test123456', 12)
    const testUser = await prisma.user.upsert({
      where: { email: 'test@shortlink.com' },
      update: {},
      create: {
        email: 'test@shortlink.com',
        username: 'testuser',
        password: testPassword,
        role: 'USER',
        isActive: true,
      },
    })
    console.log('✅ 测试用户创建完成')
    console.log('   邮箱: test@shortlink.com')
    console.log('   密码: test123456')

    // 为测试用户创建用户设置
    await prisma.userSettings.upsert({
      where: { userId: testUser.id },
      update: {},
      create: {
        userId: testUser.id,
        defaultDomain: 'localhost:3000',
        enableAnalytics: true,
        enableNotifications: true,
        apiKeyEnabled: false,
      },
    })

    // 创建示例短链接
    const sampleLinks = [
      {
        shortCode: 'github',
        originalUrl: 'https://github.com',
        title: 'GitHub',
        description: '全球最大的代码托管平台',
        tags: ['开发', '代码'],
      },
      {
        shortCode: 'google',
        originalUrl: 'https://google.com',
        title: 'Google',
        description: '全球最大的搜索引擎',
        tags: ['搜索', '工具'],
      },
      {
        shortCode: 'example',
        originalUrl: 'https://example.com',
        title: 'Example',
        description: '示例网站',
        tags: ['示例'],
      },
    ]

    for (const linkData of sampleLinks) {
      const link = await prisma.link.upsert({
        where: { shortCode: linkData.shortCode },
        update: {},
        create: {
          ...linkData,
          userId: testUser.id,
          domain: 'localhost:3000',
          isActive: true,
          isPublic: true,
        },
      })

      // 创建对应的统计记录
      await prisma.linkStats.upsert({
        where: { linkId: link.id },
        update: {},
        create: {
          linkId: link.id,
          totalClicks: Math.floor(Math.random() * 100),
          uniqueClicks: Math.floor(Math.random() * 50),
        },
      })
    }
    console.log('✅ 示例短链接创建完成')

    // 创建一些示例点击记录
    const links = await prisma.link.findMany({
      where: { userId: testUser.id },
    })

    for (const link of links) {
      const clickCount = Math.floor(Math.random() * 20) + 5
      for (let i = 0; i < clickCount; i++) {
        const randomDate = new Date()
        randomDate.setDate(randomDate.getDate() - Math.floor(Math.random() * 30))
        
        await prisma.click.create({
          data: {
            linkId: link.id,
            ip: `192.168.1.${Math.floor(Math.random() * 255)}`,
            userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            referer: Math.random() > 0.5 ? 'https://google.com' : null,
            country: ['中国', '美国', '日本', '德国', '英国'][Math.floor(Math.random() * 5)],
            city: ['北京', '上海', '纽约', '东京', '柏林'][Math.floor(Math.random() * 5)],
            device: Math.random() > 0.7 ? 'mobile' : 'desktop',
            browser: ['Chrome', 'Firefox', 'Safari', 'Edge'][Math.floor(Math.random() * 4)],
            os: ['Windows', 'macOS', 'Linux', 'Android', 'iOS'][Math.floor(Math.random() * 5)],
            createdAt: randomDate,
          },
        })
      }
    }
    console.log('✅ 示例点击记录创建完成')

    console.log('🎉 数据库种子数据初始化完成！')
    console.log('')
    console.log('🔑 登录信息:')
    console.log('管理员 - admin@shortlink.com / admin123456')
    console.log('测试用户 - test@shortlink.com / test123456')
    console.log('')
    console.log('🔗 示例短链接:')
    console.log('http://localhost:3000/github')
    console.log('http://localhost:3000/google')
    console.log('http://localhost:3000/example')

  } catch (error) {
    console.error('❌ 种子数据初始化失败:', error)
    throw error
  }
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
