"""
短链接管理系统 - 主应用入口
"""
import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
import uvicorn

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.config import settings
from app.core.database import init_db, close_db
from app.api.v1.api import api_router
from app.api.redirect import redirect_router
from app.core.exceptions import ShortLinkException
from app.core.logging import setup_logging


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时执行
    setup_logging()
    await init_db()
    print("🚀 短链接服务已启动")
    print(f"📡 服务地址: http://{settings.HOST}:{settings.PORT}")
    print(f"🌍 环境: {'生产' if not settings.DEBUG else '开发'}")
    print(f"📚 API文档: http://{settings.HOST}:{settings.PORT}/docs")
    
    yield
    
    # 关闭时执行
    await close_db()
    print("👋 短链接服务已关闭")


# 创建FastAPI应用
app = FastAPI(
    title="短链接管理系统",
    description="专业的短链接管理平台API",
    version="1.0.0",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加受信任主机中间件
if not settings.DEBUG:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=["localhost", "127.0.0.1", settings.DEFAULT_DOMAIN]
    )

# 静态文件服务
if not os.path.exists("static"):
    os.makedirs("static")
app.mount("/static", StaticFiles(directory="static"), name="static")

# 注册路由
app.include_router(api_router, prefix="/api/v1")
app.include_router(redirect_router)

# 健康检查
@app.get("/health")
async def health_check():
    """健康检查接口"""
    return {
        "status": "ok",
        "version": "1.0.0",
        "timestamp": "2024-01-01T00:00:00Z"
    }

# 根路径
@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "短链接管理系统API",
        "version": "1.0.0",
        "docs": "/docs" if settings.DEBUG else None
    }

# 全局异常处理
@app.exception_handler(ShortLinkException)
async def shortlink_exception_handler(request: Request, exc: ShortLinkException):
    """处理自定义异常"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.message,
            "code": exc.code,
            "details": exc.details
        }
    )

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """处理HTTP异常"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.detail,
            "code": f"HTTP_{exc.status_code}"
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """处理通用异常"""
    if settings.DEBUG:
        import traceback
        return JSONResponse(
            status_code=500,
            content={
                "error": str(exc),
                "code": "INTERNAL_ERROR",
                "traceback": traceback.format_exc()
            }
        )
    else:
        return JSONResponse(
            status_code=500,
            content={
                "error": "服务器内部错误",
                "code": "INTERNAL_ERROR"
            }
        )


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.RELOAD,
        log_level="info" if settings.DEBUG else "warning"
    )
