"""
短链接重定向路由
"""
from fastapi import APIRouter, Request, HTTPException, Form, Depends
from fastapi.responses import RedirectResponse, HTMLResponse
from sqlalchemy.orm import Session
from datetime import datetime

from ..core.database import get_db
from ..models.link import Link
from ..models.stats import LinkStats
from ..core.exceptions import NotFoundError
from ..utils.analytics import parse_user_agent, get_client_ip

router = APIRouter()


@router.get("/{short_code}")
async def redirect_short_link(
    short_code: str,
    request: Request,
    db: Session = Depends(get_db)
):
    """短链接重定向"""
    # 查找短链接
    link = db.query(Link).filter(Link.short_code == short_code).first()
    
    if not link:
        raise HTTPException(status_code=404, detail="短链接不存在")
    
    # 检查链接是否可访问
    if not link.is_accessible:
        if link.is_expired:
            raise HTTPException(status_code=410, detail="短链接已过期")
        else:
            raise HTTPException(status_code=403, detail="短链接已被禁用")
    
    # 如果需要密码验证
    if link.password:
        # 检查是否已验证密码（通过session或cookie）
        password_verified = request.session.get(f"verified_{short_code}", False)
        if not password_verified:
            # 返回密码验证页面
            return HTMLResponse(content=get_password_form(short_code, link.title))
    
    # 记录访问统计
    await record_click_stats(request, link, db)
    
    # 更新点击计数
    link.click_count += 1
    db.commit()
    
    # 重定向到原始URL
    return RedirectResponse(url=link.original_url, status_code=302)


@router.post("/{short_code}/verify")
async def verify_password(
    short_code: str,
    password: str = Form(...),
    request: Request = None,
    db: Session = Depends(get_db)
):
    """验证短链接密码"""
    link = db.query(Link).filter(Link.short_code == short_code).first()
    
    if not link:
        raise HTTPException(status_code=404, detail="短链接不存在")
    
    if not link.password or link.password != password:
        return HTMLResponse(
            content=get_password_form(short_code, link.title, error="密码错误"),
            status_code=400
        )
    
    # 密码验证成功，设置session
    request.session[f"verified_{short_code}"] = True
    
    # 记录访问统计
    await record_click_stats(request, link, db)
    
    # 更新点击计数
    link.click_count += 1
    db.commit()
    
    # 重定向到原始URL
    return RedirectResponse(url=link.original_url, status_code=302)


async def record_click_stats(request: Request, link: Link, db: Session):
    """记录点击统计"""
    try:
        # 获取客户端信息
        ip_address = get_client_ip(request)
        user_agent = request.headers.get("user-agent", "")
        referer = request.headers.get("referer", "")
        
        # 解析用户代理
        ua_info = parse_user_agent(user_agent)
        
        # 创建统计记录
        stats = LinkStats(
            link_id=link.id,
            ip_address=ip_address,
            user_agent=user_agent,
            referer=referer,
            device_type=ua_info.get("device_type"),
            browser=ua_info.get("browser"),
            os=ua_info.get("os"),
            # 地理位置信息可以通过IP地址查询服务获取
            # country=get_country_by_ip(ip_address),
            # city=get_city_by_ip(ip_address),
        )
        
        db.add(stats)
        db.commit()
    except Exception as e:
        # 统计记录失败不应该影响重定向
        print(f"记录统计失败: {e}")


def get_password_form(short_code: str, title: str = None, error: str = None) -> str:
    """生成密码验证表单HTML"""
    error_html = f'<div class="error">{error}</div>' if error else ''
    
    return f"""
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>访问验证 - 短链接管理系统</title>
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                margin: 0;
                padding: 20px;
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
            }}
            .container {{
                background: white;
                padding: 40px;
                border-radius: 8px;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
                width: 100%;
                max-width: 400px;
                text-align: center;
            }}
            .title {{
                color: #333;
                margin-bottom: 10px;
                font-size: 24px;
            }}
            .subtitle {{
                color: #666;
                margin-bottom: 30px;
                font-size: 14px;
            }}
            .form-group {{
                margin-bottom: 20px;
                text-align: left;
            }}
            label {{
                display: block;
                margin-bottom: 5px;
                color: #333;
                font-weight: 500;
            }}
            input[type="password"] {{
                width: 100%;
                padding: 12px;
                border: 1px solid #ddd;
                border-radius: 4px;
                font-size: 16px;
                box-sizing: border-box;
            }}
            input[type="password"]:focus {{
                outline: none;
                border-color: #667eea;
                box-shadow: 0 0 0 2px rgba(102, 126, 234, 0.2);
            }}
            .submit-btn {{
                width: 100%;
                padding: 12px;
                background: #667eea;
                color: white;
                border: none;
                border-radius: 4px;
                font-size: 16px;
                cursor: pointer;
                transition: background 0.3s;
            }}
            .submit-btn:hover {{
                background: #5a6fd8;
            }}
            .error {{
                color: #e74c3c;
                margin-bottom: 20px;
                padding: 10px;
                background: #fdf2f2;
                border: 1px solid #fecaca;
                border-radius: 4px;
                font-size: 14px;
            }}
            .link-info {{
                background: #f8f9fa;
                padding: 15px;
                border-radius: 4px;
                margin-bottom: 20px;
                font-size: 14px;
                color: #666;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1 class="title">🔒 访问验证</h1>
            <p class="subtitle">此链接需要密码才能访问</p>
            
            {f'<div class="link-info">链接标题: {title}</div>' if title else ''}
            {error_html}
            
            <form method="post" action="/{short_code}/verify">
                <div class="form-group">
                    <label for="password">请输入访问密码:</label>
                    <input type="password" id="password" name="password" required autofocus>
                </div>
                <button type="submit" class="submit-btn">访问链接</button>
            </form>
        </div>
    </body>
    </html>
    """
