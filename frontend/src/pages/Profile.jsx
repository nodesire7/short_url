import React from 'react'
import { Card, Empty } from 'antd'

const Profile = () => {
  return (
    <Card title="个人资料">
      <Empty
        description="个人资料功能开发中"
        style={{ padding: '60px 0' }}
      />
    </Card>
  )
}

export default Profile
