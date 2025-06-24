"""
短链接模型
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from ..core.database import Base


class Link(Base):
    """短链接表"""
    __tablename__ = "links"
    
    id = Column(Integer, primary_key=True, index=True, comment="链接ID")
    short_code = Column(String(10), unique=True, index=True, nullable=False, comment="短链接代码")
    original_url = Column(Text, nullable=False, comment="原始URL")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, comment="创建用户ID")
    title = Column(String(255), nullable=True, comment="链接标题")
    description = Column(Text, nullable=True, comment="链接描述")
    domain = Column(String(255), default="localhost:9848", comment="短链接域名")
    expires_at = Column(DateTime, nullable=True, comment="过期时间")
    is_active = Column(Boolean, default=True, comment="是否激活")
    click_count = Column(Integer, default=0, comment="点击次数")
    password = Column(String(255), nullable=True, comment="访问密码")
    tags = Column(JSON, nullable=True, comment="标签")
    created_at = Column(
        DateTime, 
        server_default=func.now(), 
        index=True,
        comment="创建时间"
    )
    updated_at = Column(
        DateTime, 
        server_default=func.now(), 
        onupdate=func.now(), 
        comment="更新时间"
    )
    
    # 关联关系
    user = relationship("User", back_populates="links")
    stats = relationship("LinkStats", back_populates="link", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Link(id={self.id}, short_code='{self.short_code}', user_id={self.user_id})>"
    
    @property
    def short_url(self) -> str:
        """完整的短链接URL"""
        return f"http://{self.domain}/{self.short_code}"
    
    @property
    def is_expired(self) -> bool:
        """是否已过期"""
        if self.expires_at is None:
            return False
        from datetime import datetime
        return datetime.utcnow() > self.expires_at
    
    @property
    def is_accessible(self) -> bool:
        """是否可访问"""
        return self.is_active and not self.is_expired
