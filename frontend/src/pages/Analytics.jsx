import React from 'react'
import { Card, Row, Col, Statistic, Empty } from 'antd'
import { BarChartOutlined, EyeOutlined, GlobalOutlined, MobileOutlined } from '@ant-design/icons'

const Analytics = () => {
  return (
    <div>
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="总访问量"
              value={12847}
              prefix={<EyeOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="独立访客"
              value={8934}
              prefix={<GlobalOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="移动端访问"
              value={6521}
              prefix={<MobileOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="今日访问"
              value={342}
              prefix={<BarChartOutlined />}
              valueStyle={{ color: '#fa8c16' }}
            />
          </Card>
        </Col>
      </Row>

      <Card title="数据分析">
        <Empty
          description="数据分析功能开发中"
          style={{ padding: '60px 0' }}
        />
      </Card>
    </div>
  )
}

export default Analytics
