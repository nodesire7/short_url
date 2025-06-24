"""
认证相关数据模式
"""
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class Token(BaseModel):
    """访问令牌响应"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: dict


class TokenData(BaseModel):
    """令牌数据"""
    user_id: Optional[int] = None


class UserCreate(BaseModel):
    """用户创建请求"""
    email: EmailStr = Field(..., description="邮箱地址")
    username: str = Field(..., min_length=2, max_length=50, description="用户名")
    password: str = Field(..., min_length=6, max_length=50, description="密码")


class UserLogin(BaseModel):
    """用户登录请求"""
    email: EmailStr = Field(..., description="邮箱地址")
    password: str = Field(..., description="密码")


class UserResponse(BaseModel):
    """用户信息响应"""
    id: int
    email: str
    username: str
    role: str
    status: str
    avatar: Optional[str] = None
    last_login_at: Optional[str] = None
    created_at: str
    updated_at: str
    
    class Config:
        from_attributes = True
