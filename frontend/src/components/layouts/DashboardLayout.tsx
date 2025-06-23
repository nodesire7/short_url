import { useState } from 'react'
import { Outlet } from 'react-router-dom'
import { Helmet } from 'react-helmet-async'
import Sidebar from '@/components/navigation/Sidebar'
import Header from '@/components/navigation/Header'

export default function DashboardLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)

  return (
    <>
      <Helmet>
        <title>仪表板 - Modern ShortLink</title>
        <meta name="description" content="现代化短链接系统管理面板" />
      </Helmet>
      
      <div className="min-h-screen bg-gray-50">
        {/* 移动端侧边栏遮罩 */}
        {sidebarOpen && (
          <div
            className="fixed inset-0 z-40 bg-gray-600 bg-opacity-75 lg:hidden"
            onClick={() => setSidebarOpen(false)}
          />
        )}

        {/* 侧边栏 */}
        <Sidebar 
          isOpen={sidebarOpen} 
          onClose={() => setSidebarOpen(false)} 
        />

        {/* 主内容区域 */}
        <div className="lg:pl-64">
          {/* 顶部导航 */}
          <Header onMenuClick={() => setSidebarOpen(true)} />
          
          {/* 页面内容 */}
          <main className="py-6">
            <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
              <Outlet />
            </div>
          </main>
        </div>
      </div>
    </>
  )
}
