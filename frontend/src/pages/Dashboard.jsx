import React from 'react'
import { Row, Col, Card, Statistic, Typography, Space, Button } from 'antd'
import {
  LinkOutlined,
  EyeOutlined,
  UserOutlined,
  TrophyOutlined,
  PlusOutlined,
  BarChartOutlined,
} from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'

const { Title, Paragraph } = Typography

const Dashboard = () => {
  const navigate = useNavigate()
  const { user } = useAuthStore()

  // 模拟统计数据（实际项目中应该从API获取）
  const stats = {
    totalLinks: 156,
    totalClicks: 12847,
    totalUsers: user?.role === 'admin' ? 23 : null,
    todayClicks: 342,
  }

  const quickActions = [
    {
      title: '创建短链接',
      description: '快速创建新的短链接',
      icon: <PlusOutlined />,
      action: () => navigate('/links'),
      color: '#1890ff',
    },
    {
      title: '查看分析',
      description: '查看详细的访问统计',
      icon: <BarChartOutlined />,
      action: () => navigate('/analytics'),
      color: '#52c41a',
    },
  ]

  return (
    <div>
      {/* 欢迎信息 */}
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ marginBottom: 8 }}>
          欢迎回来，{user?.username || user?.email}！
        </Title>
        <Paragraph type="secondary">
          这里是您的短链接管理仪表板，您可以查看统计信息和快速执行操作。
        </Paragraph>
      </div>

      {/* 统计卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="总链接数"
              value={stats.totalLinks}
              prefix={<LinkOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="总点击数"
              value={stats.totalClicks}
              prefix={<EyeOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        {user?.role === 'admin' && (
          <Col xs={24} sm={12} lg={6}>
            <Card>
              <Statistic
                title="用户总数"
                value={stats.totalUsers}
                prefix={<UserOutlined />}
                valueStyle={{ color: '#722ed1' }}
              />
            </Card>
          </Col>
        )}
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="今日点击"
              value={stats.todayClicks}
              prefix={<TrophyOutlined />}
              valueStyle={{ color: '#fa8c16' }}
            />
          </Card>
        </Col>
      </Row>

      {/* 快速操作 */}
      <Card title="快速操作" style={{ marginBottom: 24 }}>
        <Row gutter={[16, 16]}>
          {quickActions.map((action, index) => (
            <Col xs={24} sm={12} lg={8} key={index}>
              <Card
                hoverable
                onClick={action.action}
                style={{
                  textAlign: 'center',
                  cursor: 'pointer',
                  border: `1px solid ${action.color}20`,
                }}
                bodyStyle={{ padding: '24px 16px' }}
              >
                <div
                  style={{
                    fontSize: 32,
                    color: action.color,
                    marginBottom: 16,
                  }}
                >
                  {action.icon}
                </div>
                <Title level={4} style={{ marginBottom: 8 }}>
                  {action.title}
                </Title>
                <Paragraph type="secondary" style={{ marginBottom: 0 }}>
                  {action.description}
                </Paragraph>
              </Card>
            </Col>
          ))}
        </Row>
      </Card>

      {/* 最近活动 */}
      <Card title="最近活动">
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <EyeOutlined style={{ fontSize: 48, color: '#d9d9d9', marginBottom: 16 }} />
          <Paragraph type="secondary">
            暂无最近活动数据
          </Paragraph>
          <Button type="primary" onClick={() => navigate('/links')}>
            创建第一个短链接
          </Button>
        </div>
      </Card>
    </div>
  )
}

export default Dashboard
