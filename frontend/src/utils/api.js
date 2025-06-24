import axios from 'axios'
import toast from 'react-hot-toast'

// 创建axios实例
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://0.0.0.0:9848',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    // 添加API版本前缀
    if (!config.url.startsWith('/api/')) {
      config.url = `/api/v1${config.url}`
    }
    
    // 添加时间戳防止缓存
    if (config.method === 'get') {
      config.params = {
        ...config.params,
        _t: Date.now(),
      }
    }
    
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  (response) => {
    return response
  },
  (error) => {
    // 处理网络错误
    if (!error.response) {
      toast.error('网络连接失败，请检查网络设置')
      return Promise.reject(error)
    }

    const { status, data } = error.response

    // 处理不同的HTTP状态码
    switch (status) {
      case 400:
        toast.error(data?.error || '请求参数错误')
        break
      case 401:
        toast.error('登录已过期，请重新登录')
        // 清除本地存储的认证信息
        localStorage.removeItem('auth-storage')
        // 重定向到登录页
        window.location.href = '/login'
        break
      case 403:
        toast.error(data?.error || '权限不足')
        break
      case 404:
        toast.error(data?.error || '请求的资源不存在')
        break
      case 409:
        toast.error(data?.error || '数据冲突')
        break
      case 429:
        toast.error(data?.error || '请求过于频繁，请稍后再试')
        break
      case 500:
        toast.error(data?.error || '服务器内部错误')
        break
      default:
        toast.error(data?.error || `请求失败 (${status})`)
    }

    return Promise.reject(error)
  }
)

export default api
