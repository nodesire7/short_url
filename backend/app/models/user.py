"""
用户模型
"""
from sqlalchemy import Column, Integer, String, Enum, DateTime, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from ..core.database import Base


class User(Base):
    """用户表"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True, comment="用户ID")
    email = Column(String(255), unique=True, index=True, nullable=False, comment="邮箱")
    password = Column(String(255), nullable=False, comment="密码哈希")
    username = Column(String(100), nullable=False, comment="用户名")
    role = Column(
        Enum("admin", "user", name="user_role"), 
        default="user", 
        comment="用户角色"
    )
    status = Column(
        Enum("active", "inactive", name="user_status"), 
        default="active", 
        comment="用户状态"
    )
    avatar = Column(String(500), nullable=True, comment="头像URL")
    last_login_at = Column(DateTime, nullable=True, comment="最后登录时间")
    created_at = Column(
        DateTime, 
        server_default=func.now(), 
        comment="创建时间"
    )
    updated_at = Column(
        DateTime, 
        server_default=func.now(), 
        onupdate=func.now(), 
        comment="更新时间"
    )
    
    # 关联关系
    links = relationship("Link", back_populates="user", cascade="all, delete-orphan")
    sessions = relationship("UserSession", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', role='{self.role}')>"
    
    @property
    def is_admin(self) -> bool:
        """是否为管理员"""
        return self.role == "admin"
    
    @property
    def is_active(self) -> bool:
        """是否为活跃用户"""
        return self.status == "active"
