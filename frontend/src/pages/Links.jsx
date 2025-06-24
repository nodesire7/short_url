import React, { useState } from 'react'
import {
  Card,
  Button,
  Table,
  Space,
  Tag,
  Modal,
  Form,
  Input,
  DatePicker,
  Switch,
  message,
  Popconfirm,
  Typography,
  Row,
  Col,
  Statistic,
} from 'antd'
import {
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  CopyOutlined,
  EyeOutlined,
  QrcodeOutlined,
  LinkOutlined,
} from '@ant-design/icons'
import { QRCodeSVG } from 'qrcode.react'
import copy from 'copy-to-clipboard'
import dayjs from 'dayjs'

const { Title, Text } = Typography
const { TextArea } = Input

const Links = () => {
  const [links, setLinks] = useState([
    {
      id: 1,
      short_code: 'abc123',
      original_url: 'https://www.example.com',
      title: '示例网站',
      description: '这是一个示例网站',
      click_count: 156,
      is_active: true,
      expires_at: null,
      created_at: '2024-01-01T12:00:00Z',
    },
    {
      id: 2,
      short_code: 'def456',
      original_url: 'https://www.google.com',
      title: 'Google搜索',
      description: '谷歌搜索引擎',
      click_count: 89,
      is_active: true,
      expires_at: '2024-12-31T23:59:59Z',
      created_at: '2024-01-02T10:30:00Z',
    },
  ])

  const [modalVisible, setModalVisible] = useState(false)
  const [qrModalVisible, setQrModalVisible] = useState(false)
  const [editingLink, setEditingLink] = useState(null)
  const [selectedLink, setSelectedLink] = useState(null)
  const [form] = Form.useForm()

  // 复制链接
  const handleCopy = (shortCode) => {
    const url = `${window.location.origin}/${shortCode}`
    copy(url)
    message.success('链接已复制到剪贴板')
  }

  // 显示二维码
  const showQRCode = (link) => {
    setSelectedLink(link)
    setQrModalVisible(true)
  }

  // 创建/编辑链接
  const handleSubmit = async (values) => {
    try {
      if (editingLink) {
        // 更新链接
        const updatedLinks = links.map(link =>
          link.id === editingLink.id ? { ...link, ...values } : link
        )
        setLinks(updatedLinks)
        message.success('链接更新成功')
      } else {
        // 创建新链接
        const newLink = {
          id: Date.now(),
          short_code: values.short_code || Math.random().toString(36).substr(2, 6),
          ...values,
          click_count: 0,
          created_at: new Date().toISOString(),
        }
        setLinks([newLink, ...links])
        message.success('链接创建成功')
      }
      setModalVisible(false)
      setEditingLink(null)
      form.resetFields()
    } catch (error) {
      message.error('操作失败')
    }
  }

  // 删除链接
  const handleDelete = (id) => {
    setLinks(links.filter(link => link.id !== id))
    message.success('链接删除成功')
  }

  // 切换链接状态
  const toggleStatus = (id) => {
    const updatedLinks = links.map(link =>
      link.id === id ? { ...link, is_active: !link.is_active } : link
    )
    setLinks(updatedLinks)
    message.success('状态更新成功')
  }

  // 打开创建/编辑模态框
  const openModal = (link = null) => {
    setEditingLink(link)
    if (link) {
      form.setFieldsValue({
        ...link,
        expires_at: link.expires_at ? dayjs(link.expires_at) : null,
      })
    } else {
      form.resetFields()
    }
    setModalVisible(true)
  }

  const columns = [
    {
      title: '短链接',
      dataIndex: 'short_code',
      key: 'short_code',
      render: (code) => (
        <Space>
          <Text code>{code}</Text>
          <Button
            type="text"
            size="small"
            icon={<CopyOutlined />}
            onClick={() => handleCopy(code)}
          />
        </Space>
      ),
    },
    {
      title: '标题',
      dataIndex: 'title',
      key: 'title',
      render: (title, record) => (
        <div>
          <div style={{ fontWeight: 500 }}>{title || '未设置标题'}</div>
          <Text type="secondary" style={{ fontSize: 12 }}>
            {record.original_url}
          </Text>
        </div>
      ),
    },
    {
      title: '点击数',
      dataIndex: 'click_count',
      key: 'click_count',
      sorter: (a, b) => a.click_count - b.click_count,
      render: (count) => (
        <Statistic value={count} valueStyle={{ fontSize: 14 }} />
      ),
    },
    {
      title: '状态',
      dataIndex: 'is_active',
      key: 'is_active',
      render: (active, record) => {
        const isExpired = record.expires_at && dayjs().isAfter(dayjs(record.expires_at))
        if (isExpired) {
          return <Tag color="red">已过期</Tag>
        }
        return (
          <Tag color={active ? 'green' : 'red'}>
            {active ? '活跃' : '禁用'}
          </Tag>
        )
      },
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date) => dayjs(date).format('YYYY-MM-DD HH:mm'),
      sorter: (a, b) => dayjs(a.created_at).unix() - dayjs(b.created_at).unix(),
    },
    {
      title: '操作',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button
            type="text"
            size="small"
            icon={<QrcodeOutlined />}
            onClick={() => showQRCode(record)}
          />
          <Button
            type="text"
            size="small"
            icon={<EditOutlined />}
            onClick={() => openModal(record)}
          />
          <Switch
            size="small"
            checked={record.is_active}
            onChange={() => toggleStatus(record.id)}
          />
          <Popconfirm
            title="确定要删除这个链接吗？"
            onConfirm={() => handleDelete(record.id)}
            okText="确定"
            cancelText="取消"
          >
            <Button
              type="text"
              size="small"
              danger
              icon={<DeleteOutlined />}
            />
          </Popconfirm>
        </Space>
      ),
    },
  ]

  return (
    <div>
      {/* 统计卡片 */}
      <Row gutter={16} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic
              title="总链接数"
              value={links.length}
              prefix={<LinkOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic
              title="总点击数"
              value={links.reduce((sum, link) => sum + link.click_count, 0)}
              prefix={<EyeOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic
              title="活跃链接"
              value={links.filter(link => link.is_active).length}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
      </Row>

      {/* 链接列表 */}
      <Card
        title={<Title level={4}>短链接管理</Title>}
        extra={
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => openModal()}
          >
            创建短链接
          </Button>
        }
      >
        <Table
          columns={columns}
          dataSource={links}
          rowKey="id"
          pagination={{
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条记录`,
          }}
        />
      </Card>

      {/* 创建/编辑模态框 */}
      <Modal
        title={editingLink ? '编辑短链接' : '创建短链接'}
        open={modalVisible}
        onCancel={() => {
          setModalVisible(false)
          setEditingLink(null)
          form.resetFields()
        }}
        footer={null}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
        >
          <Form.Item
            name="original_url"
            label="原始URL"
            rules={[
              { required: true, message: '请输入原始URL' },
              { type: 'url', message: '请输入有效的URL' },
            ]}
          >
            <Input placeholder="https://www.example.com" />
          </Form.Item>

          <Form.Item
            name="short_code"
            label="自定义短代码（可选）"
            rules={[
              { pattern: /^[a-zA-Z0-9-]{4,10}$/, message: '短代码只能包含字母、数字和连字符，长度4-10位' },
            ]}
          >
            <Input placeholder="留空则自动生成" />
          </Form.Item>

          <Form.Item name="title" label="标题">
            <Input placeholder="链接标题" />
          </Form.Item>

          <Form.Item name="description" label="描述">
            <TextArea rows={3} placeholder="链接描述" />
          </Form.Item>

          <Form.Item name="expires_at" label="过期时间">
            <DatePicker
              showTime
              placeholder="选择过期时间（可选）"
              style={{ width: '100%' }}
            />
          </Form.Item>

          <Form.Item name="password" label="访问密码">
            <Input.Password placeholder="设置访问密码（可选）" />
          </Form.Item>

          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit">
                {editingLink ? '更新' : '创建'}
              </Button>
              <Button onClick={() => setModalVisible(false)}>
                取消
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>

      {/* 二维码模态框 */}
      <Modal
        title="二维码"
        open={qrModalVisible}
        onCancel={() => setQrModalVisible(false)}
        footer={null}
        width={400}
      >
        {selectedLink && (
          <div style={{ textAlign: 'center' }}>
            <QRCodeSVG
              value={`${window.location.origin}/${selectedLink.short_code}`}
              size={200}
              style={{ marginBottom: 16 }}
            />
            <div>
              <Text strong>{selectedLink.title || '短链接'}</Text>
            </div>
            <div>
              <Text code>{`${window.location.origin}/${selectedLink.short_code}`}</Text>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}

export default Links
