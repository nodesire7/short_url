"""
用户会话模型
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from ..core.database import Base


class UserSession(Base):
    """用户会话表"""
    __tablename__ = "user_sessions"
    
    id = Column(Integer, primary_key=True, index=True, comment="会话ID")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, comment="用户ID")
    session_token = Column(String(255), unique=True, index=True, nullable=False, comment="会话令牌")
    expires_at = Column(DateTime, nullable=False, index=True, comment="过期时间")
    ip_address = Column(String(45), comment="IP地址")
    user_agent = Column(Text, comment="用户代理")
    created_at = Column(
        DateTime, 
        server_default=func.now(), 
        comment="创建时间"
    )
    
    # 关联关系
    user = relationship("User", back_populates="sessions")
    
    def __repr__(self):
        return f"<UserSession(id={self.id}, user_id={self.user_id})>"
    
    @property
    def is_expired(self) -> bool:
        """是否已过期"""
        from datetime import datetime
        return datetime.utcnow() > self.expires_at
