import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import api from '../utils/api'
import toast from 'react-hot-toast'

export const useAuthStore = create(
  persist(
    (set, get) => ({
      // 状态
      user: null,
      token: null,
      isAuthenticated: false,
      loading: false,

      // 登录
      login: async (credentials) => {
        set({ loading: true })
        try {
          const formData = new FormData()
          formData.append('username', credentials.email)
          formData.append('password', credentials.password)
          
          const response = await api.post('/auth/login', formData, {
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          })
          
          const { access_token, user } = response.data
          
          set({
            user,
            token: access_token,
            isAuthenticated: true,
            loading: false,
          })
          
          // 设置API默认token
          api.defaults.headers.common['Authorization'] = `Bearer ${access_token}`
          
          toast.success('登录成功')
          return { success: true }
        } catch (error) {
          set({ loading: false })
          const message = error.response?.data?.error || '登录失败'
          toast.error(message)
          return { success: false, error: message }
        }
      },

      // 注册
      register: async (userData) => {
        set({ loading: true })
        try {
          const response = await api.post('/auth/register', userData)
          set({ loading: false })
          toast.success('注册成功，请登录')
          return { success: true, data: response.data }
        } catch (error) {
          set({ loading: false })
          const message = error.response?.data?.error || '注册失败'
          toast.error(message)
          return { success: false, error: message }
        }
      },

      // 登出
      logout: async () => {
        try {
          await api.post('/auth/logout')
        } catch (error) {
          console.error('Logout error:', error)
        } finally {
          set({
            user: null,
            token: null,
            isAuthenticated: false,
          })
          
          // 清除API默认token
          delete api.defaults.headers.common['Authorization']
          
          toast.success('已退出登录')
        }
      },

      // 获取当前用户信息
      getCurrentUser: async () => {
        try {
          const response = await api.get('/auth/me')
          set({ user: response.data })
          return response.data
        } catch (error) {
          console.error('Get current user error:', error)
          // 如果获取用户信息失败，可能token已过期
          if (error.response?.status === 401) {
            get().logout()
          }
          throw error
        }
      },

      // 更新用户信息
      updateProfile: async (userData) => {
        try {
          const response = await api.put('/auth/me', userData)
          set({ user: response.data })
          toast.success('个人信息更新成功')
          return { success: true, data: response.data }
        } catch (error) {
          const message = error.response?.data?.error || '更新失败'
          toast.error(message)
          return { success: false, error: message }
        }
      },

      // 初始化认证状态
      initAuth: () => {
        const { token } = get()
        if (token) {
          api.defaults.headers.common['Authorization'] = `Bearer ${token}`
          // 验证token有效性
          get().getCurrentUser().catch(() => {
            get().logout()
          })
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)

// 初始化认证状态
useAuthStore.getState().initAuth()
