"""
自定义异常类
"""
from typing import Optional, Any


class ShortLinkException(Exception):
    """短链接系统基础异常"""
    
    def __init__(
        self,
        message: str,
        status_code: int = 400,
        code: str = "SHORTLINK_ERROR",
        details: Optional[Any] = None
    ):
        self.message = message
        self.status_code = status_code
        self.code = code
        self.details = details
        super().__init__(self.message)


class ValidationError(ShortLinkException):
    """数据验证错误"""
    
    def __init__(self, message: str, details: Optional[Any] = None):
        super().__init__(
            message=message,
            status_code=400,
            code="VALIDATION_ERROR",
            details=details
        )


class AuthenticationError(ShortLinkException):
    """认证错误"""
    
    def __init__(self, message: str = "认证失败"):
        super().__init__(
            message=message,
            status_code=401,
            code="AUTHENTICATION_ERROR"
        )


class AuthorizationError(ShortLinkException):
    """授权错误"""
    
    def __init__(self, message: str = "权限不足"):
        super().__init__(
            message=message,
            status_code=403,
            code="AUTHORIZATION_ERROR"
        )


class NotFoundError(ShortLinkException):
    """资源不存在错误"""
    
    def __init__(self, message: str = "资源不存在"):
        super().__init__(
            message=message,
            status_code=404,
            code="NOT_FOUND_ERROR"
        )


class ConflictError(ShortLinkException):
    """冲突错误"""
    
    def __init__(self, message: str = "资源冲突"):
        super().__init__(
            message=message,
            status_code=409,
            code="CONFLICT_ERROR"
        )


class RateLimitError(ShortLinkException):
    """速率限制错误"""
    
    def __init__(self, message: str = "请求过于频繁"):
        super().__init__(
            message=message,
            status_code=429,
            code="RATE_LIMIT_ERROR"
        )


class DatabaseError(ShortLinkException):
    """数据库错误"""
    
    def __init__(self, message: str = "数据库操作失败"):
        super().__init__(
            message=message,
            status_code=500,
            code="DATABASE_ERROR"
        )


class ExternalServiceError(ShortLinkException):
    """外部服务错误"""
    
    def __init__(self, message: str = "外部服务调用失败"):
        super().__init__(
            message=message,
            status_code=502,
            code="EXTERNAL_SERVICE_ERROR"
        )
