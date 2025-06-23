import { useState } from 'react'
import { Helmet } from 'react-helmet-async'

export default function LinksPage() {
  const [links] = useState([])

  return (
    <>
      <Helmet>
        <title>链接管理 - Modern ShortLink</title>
      </Helmet>
      
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">链接管理</h1>
          <p className="mt-1 text-sm text-gray-500">
            管理您的所有短链接
          </p>
        </div>

        <div className="card">
          <div className="card-body">
            <div className="text-center py-12">
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                链接管理功能开发中
              </h3>
              <p className="text-gray-500">
                完整的链接管理功能即将上线
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
