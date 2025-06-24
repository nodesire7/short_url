"""
访问统计分析工具
"""
import re
from typing import Dict, Optional
from fastapi import Request


def parse_user_agent(user_agent: str) -> Dict[str, Optional[str]]:
    """解析用户代理字符串"""
    if not user_agent:
        return {
            "browser": "Unknown",
            "os": "Unknown",
            "device_type": "Unknown"
        }
    
    # 浏览器检测
    browser = detect_browser(user_agent)
    
    # 操作系统检测
    os = detect_os(user_agent)
    
    # 设备类型检测
    device_type = detect_device_type(user_agent)
    
    return {
        "browser": browser,
        "os": os,
        "device_type": device_type
    }


def detect_browser(user_agent: str) -> str:
    """检测浏览器类型"""
    user_agent = user_agent.lower()
    
    browsers = [
        ("edg", "Microsoft Edge"),
        ("chrome", "Google Chrome"),
        ("firefox", "Mozilla Firefox"),
        ("safari", "Safari"),
        ("opera", "Opera"),
        ("ie", "Internet Explorer"),
        ("trident", "Internet Explorer"),
    ]
    
    for pattern, name in browsers:
        if pattern in user_agent:
            return name
    
    return "Unknown"


def detect_os(user_agent: str) -> str:
    """检测操作系统"""
    user_agent = user_agent.lower()
    
    os_patterns = [
        (r"windows nt 10", "Windows 10"),
        (r"windows nt 6\.3", "Windows 8.1"),
        (r"windows nt 6\.2", "Windows 8"),
        (r"windows nt 6\.1", "Windows 7"),
        (r"windows nt 6\.0", "Windows Vista"),
        (r"windows nt 5\.1", "Windows XP"),
        (r"windows", "Windows"),
        (r"mac os x", "macOS"),
        (r"macintosh", "macOS"),
        (r"iphone", "iOS"),
        (r"ipad", "iPadOS"),
        (r"android", "Android"),
        (r"linux", "Linux"),
        (r"ubuntu", "Ubuntu"),
        (r"centos", "CentOS"),
    ]
    
    for pattern, name in os_patterns:
        if re.search(pattern, user_agent):
            return name
    
    return "Unknown"


def detect_device_type(user_agent: str) -> str:
    """检测设备类型"""
    user_agent = user_agent.lower()
    
    if any(mobile in user_agent for mobile in ["mobile", "android", "iphone"]):
        return "Mobile"
    elif any(tablet in user_agent for tablet in ["tablet", "ipad"]):
        return "Tablet"
    else:
        return "Desktop"


def get_client_ip(request: Request) -> str:
    """获取客户端真实IP地址"""
    # 检查代理头
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        # 取第一个IP（客户端真实IP）
        return forwarded_for.split(",")[0].strip()
    
    real_ip = request.headers.get("x-real-ip")
    if real_ip:
        return real_ip
    
    # 如果没有代理头，使用客户端IP
    return request.client.host if request.client else "Unknown"


def get_country_by_ip(ip_address: str) -> Optional[str]:
    """根据IP地址获取国家信息"""
    # 这里可以集成第三方IP地理位置服务
    # 如 MaxMind GeoIP2, ipapi.co, ip-api.com 等
    # 示例实现（需要安装相应的库）
    
    try:
        # 示例：使用免费的ip-api.com服务
        import requests
        response = requests.get(f"http://ip-api.com/json/{ip_address}", timeout=5)
        if response.status_code == 200:
            data = response.json()
            return data.get("country")
    except Exception:
        pass
    
    return None


def get_city_by_ip(ip_address: str) -> Optional[str]:
    """根据IP地址获取城市信息"""
    try:
        import requests
        response = requests.get(f"http://ip-api.com/json/{ip_address}", timeout=5)
        if response.status_code == 200:
            data = response.json()
            return data.get("city")
    except Exception:
        pass
    
    return None


def is_bot_user_agent(user_agent: str) -> bool:
    """检测是否为爬虫/机器人"""
    if not user_agent:
        return True
    
    bot_patterns = [
        "bot", "crawler", "spider", "scraper", "curl", "wget",
        "python-requests", "java", "go-http-client", "okhttp",
        "facebookexternalhit", "twitterbot", "linkedinbot",
        "whatsapp", "telegram", "slack", "discord"
    ]
    
    user_agent_lower = user_agent.lower()
    return any(pattern in user_agent_lower for pattern in bot_patterns)


def generate_short_code(length: int = 6) -> str:
    """生成短链接代码"""
    import random
    import string
    
    # 使用字母和数字，避免容易混淆的字符
    chars = string.ascii_letters + string.digits
    chars = chars.replace('0', '').replace('O', '').replace('l', '').replace('I', '')
    
    return ''.join(random.choice(chars) for _ in range(length))


def validate_url(url: str) -> bool:
    """验证URL格式"""
    import re
    
    url_pattern = re.compile(
        r'^https?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain...
        r'localhost|'  # localhost...
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)
    
    return url_pattern.match(url) is not None


def sanitize_short_code(code: str) -> str:
    """清理短链接代码"""
    # 只保留字母、数字和连字符
    import re
    return re.sub(r'[^a-zA-Z0-9-]', '', code)
