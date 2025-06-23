import axios from 'axios'
import toast from 'react-hot-toast'

// 创建 axios 实例
export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    // 可以在这里添加请求日志
    console.log(`🚀 API Request: ${config.method?.toUpperCase()} ${config.url}`)
    return config
  },
  (error) => {
    console.error('❌ Request Error:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  (response) => {
    // 可以在这里添加响应日志
    console.log(`✅ API Response: ${response.config.method?.toUpperCase()} ${response.config.url}`, response.data)
    return response
  },
  (error) => {
    console.error('❌ Response Error:', error)
    
    // 处理不同的错误状态
    if (error.response) {
      const { status, data } = error.response
      
      switch (status) {
        case 401:
          // 未授权，清除本地存储并重定向到登录页
          localStorage.removeItem('auth-storage')
          window.location.href = '/auth/login'
          toast.error('登录已过期，请重新登录')
          break
          
        case 403:
          toast.error('权限不足')
          break
          
        case 404:
          toast.error('请求的资源不存在')
          break
          
        case 422:
          // 表单验证错误
          if (data.errors) {
            Object.values(data.errors).forEach((error: any) => {
              toast.error(error[0])
            })
          } else {
            toast.error(data.message || '请求参数错误')
          }
          break
          
        case 429:
          toast.error('请求过于频繁，请稍后再试')
          break
          
        case 500:
          toast.error('服务器内部错误')
          break
          
        default:
          toast.error(data.message || '请求失败')
      }
    } else if (error.request) {
      // 网络错误
      toast.error('网络连接失败，请检查网络设置')
    } else {
      // 其他错误
      toast.error('请求失败，请稍后重试')
    }
    
    return Promise.reject(error)
  }
)

// API 方法封装
export const apiClient = {
  // GET 请求
  get: <T = any>(url: string, params?: any) => 
    api.get<T>(url, { params }),
  
  // POST 请求
  post: <T = any>(url: string, data?: any) => 
    api.post<T>(url, data),
  
  // PUT 请求
  put: <T = any>(url: string, data?: any) => 
    api.put<T>(url, data),
  
  // DELETE 请求
  delete: <T = any>(url: string) => 
    api.delete<T>(url),
  
  // PATCH 请求
  patch: <T = any>(url: string, data?: any) => 
    api.patch<T>(url, data),
}

// 导出默认实例
export default api
