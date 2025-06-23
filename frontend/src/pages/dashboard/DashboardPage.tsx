import { useQuery } from '@tanstack/react-query'
import { Link, BarChart3, Users, TrendingUp } from 'lucide-react'
import { api } from '@/lib/api'
import { formatNumber } from '@/lib/utils'
import LoadingSpinner from '@/components/ui/LoadingSpinner'

// 统计卡片组件
interface StatsCardProps {
  title: string
  value: number
  icon: React.ComponentType<{ className?: string }>
  trend?: {
    value: number
    isPositive: boolean
  }
  color: 'blue' | 'green' | 'purple' | 'orange'
}

const colorClasses = {
  blue: 'bg-blue-500 text-blue-600 bg-blue-50',
  green: 'bg-green-500 text-green-600 bg-green-50',
  purple: 'bg-purple-500 text-purple-600 bg-purple-50',
  orange: 'bg-orange-500 text-orange-600 bg-orange-50',
}

function StatsCard({ title, value, icon: Icon, trend, color }: StatsCardProps) {
  const [, textColor, lightBg] = colorClasses[color].split(' ')

  return (
    <div className="card hover-lift group cursor-pointer">
      <div className="card-body">
        <div className="flex items-center">
          <div className="flex-shrink-0">
            <div className={`p-4 rounded-xl ${lightBg} group-hover:scale-110 transition-transform duration-200`}>
              <Icon className={`h-7 w-7 ${textColor}`} />
            </div>
          </div>
          <div className="ml-6 w-0 flex-1">
            <dl>
              <dt className="text-sm font-semibold text-gray-600 truncate uppercase tracking-wide">{title}</dt>
              <dd className="flex items-baseline mt-2">
                <div className="text-3xl font-bold text-gray-900">
                  {formatNumber(value)}
                </div>
                {trend && (
                  <div className={`ml-3 flex items-center text-sm font-semibold px-2 py-1 rounded-full ${
                    trend.isPositive
                      ? 'text-green-700 bg-green-100'
                      : 'text-red-700 bg-red-100'
                  }`}>
                    <TrendingUp className={`self-center flex-shrink-0 h-4 w-4 mr-1 ${
                      trend.isPositive ? 'text-green-600' : 'text-red-600 transform rotate-180'
                    }`} />
                    <span>
                      {trend.value}%
                    </span>
                  </div>
                )}
              </dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function DashboardPage() {
  // 获取用户统计数据
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['user-stats'],
    queryFn: async () => {
      const response = await api.get('/users/stats')
      return response.data.data
    },
  })

  // 获取最近的链接
  const { data: recentLinks, isLoading: linksLoading } = useQuery({
    queryKey: ['recent-links'],
    queryFn: async () => {
      const response = await api.get('/links?limit=5&sortBy=createdAt&sortOrder=desc')
      return response.data.data.links
    },
  })

  if (statsLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* 页面标题 */}
      <div className="bg-gradient-to-r from-primary-50 to-accent-50 rounded-2xl p-8 border border-primary-100">
        <div className="flex items-center space-x-4">
          <div className="w-12 h-12 bg-gradient-to-br from-primary-500 to-accent-500 rounded-xl flex items-center justify-center shadow-medium">
            <BarChart3 className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold gradient-text">仪表板</h1>
            <p className="mt-2 text-gray-600">
              欢迎回来！查看您的短链接统计数据和最新动态
            </p>
          </div>
        </div>
      </div>

      {/* 统计卡片 */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <StatsCard
          title="总链接数"
          value={stats?.totalLinks || 0}
          icon={Link}
          color="blue"
        />
        <StatsCard
          title="活跃链接"
          value={stats?.activeLinks || 0}
          icon={BarChart3}
          color="green"
        />
        <StatsCard
          title="总点击数"
          value={stats?.totalClicks || 0}
          icon={Users}
          color="purple"
        />
        <StatsCard
          title="最近7天点击"
          value={stats?.recentClicks || 0}
          icon={TrendingUp}
          color="orange"
        />
      </div>

      {/* 最近创建的链接 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900">最近创建的链接</h3>
          </div>
          <div className="card-body">
            {linksLoading ? (
              <div className="flex justify-center py-4">
                <LoadingSpinner />
              </div>
            ) : recentLinks && recentLinks.length > 0 ? (
              <div className="space-y-4">
                {recentLinks.map((link: any) => (
                  <div key={link.id} className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">
                        {link.title || link.originalUrl}
                      </p>
                      <p className="text-sm text-gray-500 truncate">
                        {link.shortUrl}
                      </p>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                        {link.totalClicks} 点击
                      </span>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        link.isActive 
                          ? 'bg-green-100 text-green-800' 
                          : 'bg-red-100 text-red-800'
                      }`}>
                        {link.isActive ? '活跃' : '停用'}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-6">
                <Link className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-2 text-sm font-medium text-gray-900">暂无链接</h3>
                <p className="mt-1 text-sm text-gray-500">
                  开始创建您的第一个短链接
                </p>
              </div>
            )}
          </div>
        </div>

        {/* 快速操作 */}
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900">快速操作</h3>
          </div>
          <div className="card-body">
            <div className="space-y-4">
              <a
                href="/links"
                className="block p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <Link className="h-6 w-6 text-primary-600" />
                  </div>
                  <div className="ml-3">
                    <h4 className="text-sm font-medium text-gray-900">创建新链接</h4>
                    <p className="text-sm text-gray-500">快速创建一个新的短链接</p>
                  </div>
                </div>
              </a>
              
              <a
                href="/analytics"
                className="block p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <BarChart3 className="h-6 w-6 text-primary-600" />
                  </div>
                  <div className="ml-3">
                    <h4 className="text-sm font-medium text-gray-900">查看分析</h4>
                    <p className="text-sm text-gray-500">查看详细的访问统计数据</p>
                  </div>
                </div>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
