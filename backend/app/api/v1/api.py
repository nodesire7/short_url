"""
API v1 路由汇总
"""
from fastapi import APIRouter

from .endpoints import auth, links, users, stats, config

api_router = APIRouter()

# 注册各个模块的路由
api_router.include_router(auth.router, prefix="/auth", tags=["认证"])
api_router.include_router(links.router, prefix="/links", tags=["短链接"])
api_router.include_router(users.router, prefix="/users", tags=["用户管理"])
api_router.include_router(stats.router, prefix="/stats", tags=["统计分析"])
api_router.include_router(config.router, prefix="/config", tags=["系统配置"])
