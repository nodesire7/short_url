"""
访问统计模型
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from ..core.database import Base


class LinkStats(Base):
    """访问统计表"""
    __tablename__ = "link_stats"
    
    id = Column(Integer, primary_key=True, index=True, comment="统计ID")
    link_id = Column(Integer, ForeignKey("links.id"), nullable=False, comment="链接ID")
    ip_address = Column(String(45), index=True, comment="IP地址")
    user_agent = Column(Text, comment="用户代理")
    referer = Column(Text, comment="来源页面")
    country = Column(String(100), index=True, comment="国家")
    region = Column(String(100), comment="地区")
    city = Column(String(100), comment="城市")
    device_type = Column(String(50), comment="设备类型")
    browser = Column(String(100), comment="浏览器")
    os = Column(String(100), comment="操作系统")
    clicked_at = Column(
        DateTime, 
        server_default=func.now(), 
        index=True,
        comment="点击时间"
    )
    
    # 关联关系
    link = relationship("Link", back_populates="stats")
    
    def __repr__(self):
        return f"<LinkStats(id={self.id}, link_id={self.link_id}, ip='{self.ip_address}')>"
