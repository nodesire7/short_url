"""
应用配置管理
"""
import os
from typing import List, Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """应用配置类"""
    
    # 数据库配置
    DATABASE_URL: str = Field(
        default="mysql+pymysql://root:password@localhost:3306/shortlink",
        description="数据库连接URL"
    )
    DB_HOST: str = Field(default="localhost", description="数据库主机")
    DB_PORT: int = Field(default=3306, description="数据库端口")
    DB_NAME: str = Field(default="shortlink", description="数据库名称")
    DB_USER: str = Field(default="root", description="数据库用户名")
    DB_PASSWORD: str = Field(default="password", description="数据库密码")
    
    # JWT配置
    SECRET_KEY: str = Field(
        default="your-super-secret-key-change-this-in-production",
        description="JWT密钥"
    )
    ALGORITHM: str = Field(default="HS256", description="JWT算法")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(
        default=10080, 
        description="访问令牌过期时间（分钟）"
    )
    
    # 服务器配置
    HOST: str = Field(default="0.0.0.0", description="服务器主机")
    PORT: int = Field(default=9848, description="服务器端口")
    DEBUG: bool = Field(default=True, description="调试模式")
    RELOAD: bool = Field(default=True, description="自动重载")
    
    # 短链接配置
    DEFAULT_DOMAIN: str = Field(default="localhost:9848", description="默认域名")
    SHORT_LINK_MIN_LENGTH: int = Field(default=4, description="短链接最小长度")
    SHORT_LINK_MAX_LENGTH: int = Field(default=10, description="短链接最大长度")
    ALLOW_CUSTOM_CODE: bool = Field(default=True, description="允许自定义代码")
    
    # Redis配置
    REDIS_URL: str = Field(default="redis://localhost:6379/0", description="Redis连接URL")
    ENABLE_REDIS: bool = Field(default=False, description="启用Redis")
    
    # 速率限制
    RATE_LIMIT_ENABLED: bool = Field(default=True, description="启用速率限制")
    RATE_LIMIT_REQUESTS: int = Field(default=100, description="速率限制请求数")
    RATE_LIMIT_WINDOW: int = Field(default=3600, description="速率限制时间窗口")
    
    # 文件上传
    MAX_FILE_SIZE: int = Field(default=10485760, description="最大文件大小")
    UPLOAD_DIR: str = Field(default="uploads", description="上传目录")
    
    # 邮件配置
    SMTP_HOST: Optional[str] = Field(default=None, description="SMTP主机")
    SMTP_PORT: int = Field(default=587, description="SMTP端口")
    SMTP_USER: Optional[str] = Field(default=None, description="SMTP用户名")
    SMTP_PASSWORD: Optional[str] = Field(default=None, description="SMTP密码")
    SMTP_FROM: Optional[str] = Field(default=None, description="发件人邮箱")
    
    # 管理员配置
    ADMIN_EMAIL: str = Field(default="admin@shortlink.com", description="管理员邮箱")
    ADMIN_PASSWORD: str = Field(default="admin123456", description="管理员密码")
    
    # CORS配置
    CORS_ORIGINS: List[str] = Field(
        default=["http://localhost:8848", "http://0.0.0.0:8848"],
        description="允许的跨域源"
    )
    CORS_ALLOW_CREDENTIALS: bool = Field(default=True, description="允许跨域凭证")
    
    # 日志配置
    LOG_LEVEL: str = Field(default="INFO", description="日志级别")
    LOG_FILE: Optional[str] = Field(default=None, description="日志文件路径")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# 创建全局配置实例
settings = Settings()

# 确保上传目录存在
if not os.path.exists(settings.UPLOAD_DIR):
    os.makedirs(settings.UPLOAD_DIR)
