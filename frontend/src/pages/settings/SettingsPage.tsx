import { Helmet } from 'react-helmet-async'

export default function SettingsPage() {
  return (
    <>
      <Helmet>
        <title>设置 - Modern ShortLink</title>
      </Helmet>
      
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">设置</h1>
          <p className="mt-1 text-sm text-gray-500">
            管理您的账户和系统设置
          </p>
        </div>

        <div className="card">
          <div className="card-body">
            <div className="text-center py-12">
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                设置功能开发中
              </h3>
              <p className="text-gray-500">
                完整的设置功能即将上线
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
