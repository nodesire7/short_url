import { Outlet } from 'react-router-dom'
import { Helmet } from 'react-helmet-async'
import { Link2 } from 'lucide-react'

export default function AuthLayout() {
  return (
    <>
      <Helmet>
        <title>登录 - Modern ShortLink</title>
        <meta name="description" content="现代化短链接系统登录页面" />
      </Helmet>
      
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
        <div className="flex min-h-screen">
          {/* 左侧装饰区域 */}
          <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-primary-600 to-purple-700 relative overflow-hidden">
            <div className="absolute inset-0 bg-black/10" />
            <div className="relative z-10 flex flex-col justify-center px-12 text-white">
              <div className="mb-8">
                <div className="flex items-center space-x-3 mb-6">
                  <div className="p-3 bg-white/20 rounded-xl backdrop-blur-sm">
                    <Link2 className="w-8 h-8" />
                  </div>
                  <h1 className="text-3xl font-bold">Modern ShortLink</h1>
                </div>
                <p className="text-xl text-blue-100 leading-relaxed">
                  现代化的短链接管理系统，让您的链接更简洁、更智能、更安全。
                </p>
              </div>
              
              <div className="space-y-6">
                <div className="flex items-start space-x-4">
                  <div className="w-2 h-2 bg-blue-300 rounded-full mt-3 flex-shrink-0" />
                  <div>
                    <h3 className="font-semibold mb-1">智能分析</h3>
                    <p className="text-blue-100">详细的访问统计和用户行为分析</p>
                  </div>
                </div>
                
                <div className="flex items-start space-x-4">
                  <div className="w-2 h-2 bg-purple-300 rounded-full mt-3 flex-shrink-0" />
                  <div>
                    <h3 className="font-semibold mb-1">安全可靠</h3>
                    <p className="text-blue-100">企业级安全保障，数据加密存储</p>
                  </div>
                </div>
                
                <div className="flex items-start space-x-4">
                  <div className="w-2 h-2 bg-green-300 rounded-full mt-3 flex-shrink-0" />
                  <div>
                    <h3 className="font-semibold mb-1">易于使用</h3>
                    <p className="text-blue-100">简洁直观的界面，快速上手</p>
                  </div>
                </div>
              </div>
            </div>
            
            {/* 装饰性几何图形 */}
            <div className="absolute top-20 right-20 w-32 h-32 bg-white/10 rounded-full blur-xl" />
            <div className="absolute bottom-20 left-20 w-24 h-24 bg-purple-300/20 rounded-full blur-lg" />
            <div className="absolute top-1/2 right-10 w-16 h-16 bg-blue-300/30 rounded-full blur-md" />
          </div>
          
          {/* 右侧表单区域 */}
          <div className="flex-1 flex flex-col justify-center px-6 py-12 lg:px-20 xl:px-24">
            <div className="mx-auto w-full max-w-sm lg:max-w-md">
              {/* 移动端 Logo */}
              <div className="lg:hidden mb-8 text-center">
                <div className="inline-flex items-center space-x-2 mb-4">
                  <div className="p-2 bg-primary-100 rounded-lg">
                    <Link2 className="w-6 h-6 text-primary-600" />
                  </div>
                  <h1 className="text-2xl font-bold text-gray-900">Modern ShortLink</h1>
                </div>
                <p className="text-gray-600">现代化短链接管理系统</p>
              </div>
              
              {/* 表单内容 */}
              <Outlet />
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
