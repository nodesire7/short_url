import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from 'react-query'
import { ConfigProvider } from 'antd'
import zhCN from 'antd/locale/zh_CN'
import dayjs from 'dayjs'
import 'dayjs/locale/zh-cn'
import { Toaster } from 'react-hot-toast'

import App from './App.jsx'
import './index.css'

// 设置dayjs中文
dayjs.locale('zh-cn')

// 创建React Query客户端
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 5 * 60 * 1000, // 5分钟
    },
  },
})

// Ant Design主题配置
const theme = {
  token: {
    colorPrimary: import.meta.env.VITE_THEME_PRIMARY_COLOR || '#1890ff',
    colorSuccess: import.meta.env.VITE_THEME_SUCCESS_COLOR || '#52c41a',
    colorWarning: import.meta.env.VITE_THEME_WARNING_COLOR || '#faad14',
    colorError: import.meta.env.VITE_THEME_ERROR_COLOR || '#ff4d4f',
    borderRadius: 6,
    wireframe: false,
  },
  components: {
    Layout: {
      headerBg: '#fff',
      headerHeight: 64,
      siderBg: '#001529',
    },
    Menu: {
      darkItemBg: '#001529',
      darkSubMenuItemBg: '#000c17',
    },
  },
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <ConfigProvider locale={zhCN} theme={theme}>
        <BrowserRouter>
          <App />
          <Toaster
            position="top-right"
            toastOptions={{
              duration: 3000,
              style: {
                background: '#fff',
                color: '#333',
                boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
              },
              success: {
                iconTheme: {
                  primary: '#52c41a',
                  secondary: '#fff',
                },
              },
              error: {
                iconTheme: {
                  primary: '#ff4d4f',
                  secondary: '#fff',
                },
              },
            }}
          />
        </BrowserRouter>
      </ConfigProvider>
    </QueryClientProvider>
  </React.StrictMode>,
)
