import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { api } from '@/lib/api'
import toast from 'react-hot-toast'

interface User {
  id: string
  email: string
  username: string
  role: string
  isActive: boolean
  createdAt: string
}

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
  
  // Actions
  login: (email: string, password: string) => Promise<void>
  register: (email: string, username: string, password: string) => Promise<void>
  logout: () => void
  initializeAuth: () => void
  updateUser: (user: User) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,

      login: async (email: string, password: string) => {
        try {
          set({ isLoading: true })
          
          const response = await api.post('/auth/login', {
            email,
            password,
          })

          const { user, token } = response.data.data
          
          // 设置 API 默认 token
          api.defaults.headers.common['Authorization'] = `Bearer ${token}`
          
          set({
            user,
            token,
            isAuthenticated: true,
            isLoading: false,
          })

          toast.success('登录成功')
        } catch (error: any) {
          set({ isLoading: false })
          const message = error.response?.data?.message || '登录失败'
          toast.error(message)
          throw error
        }
      },

      register: async (email: string, username: string, password: string) => {
        try {
          set({ isLoading: true })
          
          const response = await api.post('/auth/register', {
            email,
            username,
            password,
          })

          const { user, token } = response.data.data
          
          // 设置 API 默认 token
          api.defaults.headers.common['Authorization'] = `Bearer ${token}`
          
          set({
            user,
            token,
            isAuthenticated: true,
            isLoading: false,
          })

          toast.success('注册成功')
        } catch (error: any) {
          set({ isLoading: false })
          const message = error.response?.data?.message || '注册失败'
          toast.error(message)
          throw error
        }
      },

      logout: () => {
        // 清除 API token
        delete api.defaults.headers.common['Authorization']
        
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        })

        toast.success('已退出登录')
      },

      initializeAuth: () => {
        const { token } = get()
        
        if (token) {
          // 设置 API 默认 token
          api.defaults.headers.common['Authorization'] = `Bearer ${token}`
          
          // 验证 token 有效性
          api.get('/auth/me')
            .then((response) => {
              const user = response.data.data
              set({
                user,
                isAuthenticated: true,
              })
            })
            .catch(() => {
              // Token 无效，清除状态
              get().logout()
            })
        }
      },

      updateUser: (user: User) => {
        set({ user })
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        token: state.token,
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)
