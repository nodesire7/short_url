"""
用户相关数据模式
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    """用户基础信息"""
    email: EmailStr
    username: str = Field(..., min_length=2, max_length=50)


class UserCreate(BaseModel):
    """创建用户请求"""
    email: EmailStr
    username: str = Field(..., min_length=2, max_length=50)
    password: str = Field(..., min_length=6, max_length=50)
    role: Optional[str] = Field(default="user", regex="^(admin|user)$")


class UserUpdate(BaseModel):
    """更新用户请求"""
    username: Optional[str] = Field(None, min_length=2, max_length=50)
    password: Optional[str] = Field(None, min_length=6, max_length=50)
    avatar: Optional[str] = None
    status: Optional[str] = Field(None, regex="^(active|inactive)$")


class UserResponse(BaseModel):
    """用户信息响应"""
    id: int
    email: str
    username: str
    role: str
    status: str
    avatar: Optional[str] = None
    last_login_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class UserListResponse(BaseModel):
    """用户列表响应"""
    users: List[UserResponse]
    total: int
    page: int
    size: int
    pages: int
