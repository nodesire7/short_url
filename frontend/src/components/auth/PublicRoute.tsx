import { Navigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/auth'

interface PublicRouteProps {
  children: React.ReactNode
}

export default function PublicRoute({ children }: PublicRouteProps) {
  const { isAuthenticated } = useAuthStore()

  // 如果已认证，重定向到仪表板
  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />
  }

  return <>{children}</>
}
