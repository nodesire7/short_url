"""
数据库连接和会话管理
"""
from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import QueuePool
import asyncio
from typing import Generator

from .config import settings

# 创建数据库引擎
engine = create_engine(
    settings.DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=settings.DEBUG
)

# 创建会话工厂
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 创建基础模型类
Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def init_db():
    """初始化数据库"""
    try:
        # 测试数据库连接
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        print("✅ 数据库连接成功")
        
        # 创建所有表
        from app.models import user, link, stats, config, session
        Base.metadata.create_all(bind=engine)
        print("✅ 数据库表创建完成")
        
        # 初始化默认数据
        await init_default_data()
        
    except Exception as e:
        print(f"❌ 数据库初始化失败: {e}")
        raise


async def close_db():
    """关闭数据库连接"""
    try:
        engine.dispose()
        print("✅ 数据库连接已关闭")
    except Exception as e:
        print(f"❌ 关闭数据库连接失败: {e}")


async def init_default_data():
    """初始化默认数据"""
    from app.models.user import User
    from app.models.config import SystemConfig
    from app.core.security import get_password_hash
    
    db = SessionLocal()
    try:
        # 检查是否已存在管理员用户
        admin_user = db.query(User).filter(User.email == settings.ADMIN_EMAIL).first()
        if not admin_user:
            # 创建默认管理员用户
            admin_user = User(
                email=settings.ADMIN_EMAIL,
                password=get_password_hash(settings.ADMIN_PASSWORD),
                username="系统管理员",
                role="admin"
            )
            db.add(admin_user)
            print("✅ 创建默认管理员用户")
        
        # 初始化系统配置
        default_configs = [
            ("site_name", "短链接管理系统", "string", "网站名称", True),
            ("site_description", "专业的短链接管理平台", "string", "网站描述", True),
            ("default_domain", settings.DEFAULT_DOMAIN, "string", "默认短链接域名", False),
            ("short_link_min_length", str(settings.SHORT_LINK_MIN_LENGTH), "number", "短链接最小长度", False),
            ("short_link_max_length", str(settings.SHORT_LINK_MAX_LENGTH), "number", "短链接最大长度", False),
            ("allow_custom_code", str(settings.ALLOW_CUSTOM_CODE).lower(), "boolean", "允许自定义短链接代码", False),
            ("require_login", "true", "boolean", "是否需要登录才能创建链接", False),
            ("max_links_per_user", "1000", "number", "每个用户最大链接数", False),
            ("enable_analytics", "true", "boolean", "启用访问统计", False),
            ("enable_password_protection", "true", "boolean", "启用密码保护", False),
        ]
        
        for config_key, config_value, config_type, description, is_public in default_configs:
            existing_config = db.query(SystemConfig).filter(
                SystemConfig.config_key == config_key
            ).first()
            if not existing_config:
                config = SystemConfig(
                    config_key=config_key,
                    config_value=config_value,
                    config_type=config_type,
                    description=description,
                    is_public=is_public
                )
                db.add(config)
        
        db.commit()
        print("✅ 默认数据初始化完成")
        
    except Exception as e:
        db.rollback()
        print(f"❌ 默认数据初始化失败: {e}")
        raise
    finally:
        db.close()
