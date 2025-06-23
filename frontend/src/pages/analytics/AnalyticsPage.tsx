import { Helmet } from 'react-helmet-async'

export default function AnalyticsPage() {
  return (
    <>
      <Helmet>
        <title>数据分析 - Modern ShortLink</title>
      </Helmet>
      
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">数据分析</h1>
          <p className="mt-1 text-sm text-gray-500">
            查看详细的访问统计和分析数据
          </p>
        </div>

        <div className="card">
          <div className="card-body">
            <div className="text-center py-12">
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                数据分析功能开发中
              </h3>
              <p className="text-gray-500">
                完整的数据分析功能即将上线
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
