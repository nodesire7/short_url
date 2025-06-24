"""
系统配置模型
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, Enum, DateTime
from sqlalchemy.sql import func

from ..core.database import Base


class SystemConfig(Base):
    """系统配置表"""
    __tablename__ = "system_config"
    
    id = Column(Integer, primary_key=True, index=True, comment="配置ID")
    config_key = Column(String(100), unique=True, index=True, nullable=False, comment="配置键")
    config_value = Column(Text, comment="配置值")
    config_type = Column(
        Enum("string", "number", "boolean", "json", name="config_type"),
        default="string",
        comment="配置类型"
    )
    description = Column(String(255), comment="配置描述")
    is_public = Column(Boolean, default=False, index=True, comment="是否公开")
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
    
    def __repr__(self):
        return f"<SystemConfig(key='{self.config_key}', value='{self.config_value}')>"
    
    @property
    def typed_value(self):
        """根据类型返回转换后的值"""
        if self.config_type == "boolean":
            return self.config_value.lower() in ("true", "1", "yes", "on")
        elif self.config_type == "number":
            try:
                if "." in self.config_value:
                    return float(self.config_value)
                else:
                    return int(self.config_value)
            except (ValueError, TypeError):
                return 0
        elif self.config_type == "json":
            import json
            try:
                return json.loads(self.config_value)
            except (json.JSONDecodeError, TypeError):
                return {}
        else:
            return self.config_value
