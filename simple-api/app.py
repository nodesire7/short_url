#!/usr/bin/env python3
"""
简单高效的短链接API服务
端口: 2282
认证: Authorization=TaDeixjf9alwtJe5v4wv7F7cIpXM03hl
"""

from flask import Flask, request, jsonify, redirect
import sqlite3
import string
import random
import re
from datetime import datetime
import os

app = Flask(__name__)

# 配置
API_TOKEN = "TaDeixjf9alwtJe5v4wv7F7cIpXM03hl"
DATABASE = "shortlinks.db"
BASE_URL = "http://localhost:2282"
SHORT_CODE_LENGTH = 6

def init_db():
    """初始化数据库"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            short_code TEXT UNIQUE NOT NULL,
            original_url TEXT NOT NULL,
            title TEXT,
            click_count INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS clicks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            short_code TEXT NOT NULL,
            ip_address TEXT,
            user_agent TEXT,
            clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (short_code) REFERENCES links (short_code)
        )
    ''')
    
    conn.commit()
    conn.close()

def verify_auth():
    """验证Authorization"""
    auth_header = request.headers.get('Authorization')
    if not auth_header or auth_header != API_TOKEN:
        return False
    return True

def generate_short_code():
    """生成短链接代码"""
    chars = string.ascii_letters + string.digits
    while True:
        code = ''.join(random.choice(chars) for _ in range(SHORT_CODE_LENGTH))
        # 检查是否已存在
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM links WHERE short_code = ?", (code,))
        if not cursor.fetchone():
            conn.close()
            return code
        conn.close()

def is_valid_url(url):
    """验证URL格式"""
    url_pattern = re.compile(
        r'^https?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain
        r'localhost|'  # localhost
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # IP
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)
    return url_pattern.match(url) is not None

@app.route('/api/create', methods=['POST'])
def create_short_link():
    """创建短链接"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400
    
    original_url = data.get('url')
    custom_code = data.get('code')
    title = data.get('title', '')
    
    if not original_url:
        return jsonify({"error": "URL is required"}), 400
    
    if not is_valid_url(original_url):
        return jsonify({"error": "Invalid URL format"}), 400
    
    # 生成或使用自定义短代码
    if custom_code:
        if len(custom_code) < 3 or len(custom_code) > 20:
            return jsonify({"error": "Custom code must be 3-20 characters"}), 400
        if not re.match(r'^[a-zA-Z0-9_-]+$', custom_code):
            return jsonify({"error": "Custom code can only contain letters, numbers, _ and -"}), 400
        short_code = custom_code
    else:
        short_code = generate_short_code()
    
    try:
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute(
            "INSERT INTO links (short_code, original_url, title) VALUES (?, ?, ?)",
            (short_code, original_url, title)
        )
        
        conn.commit()
        conn.close()
        
        return jsonify({
            "success": True,
            "short_code": short_code,
            "short_url": f"{BASE_URL}/{short_code}",
            "original_url": original_url,
            "title": title,
            "created_at": datetime.now().isoformat()
        }), 201
        
    except sqlite3.IntegrityError:
        return jsonify({"error": "Short code already exists"}), 409
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/list', methods=['GET'])
def list_links():
    """获取链接列表"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    page = int(request.args.get('page', 1))
    limit = int(request.args.get('limit', 20))
    offset = (page - 1) * limit
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    # 获取总数
    cursor.execute("SELECT COUNT(*) FROM links")
    total = cursor.fetchone()[0]
    
    # 获取链接列表
    cursor.execute(
        "SELECT short_code, original_url, title, click_count, created_at FROM links ORDER BY created_at DESC LIMIT ? OFFSET ?",
        (limit, offset)
    )
    
    links = []
    for row in cursor.fetchall():
        links.append({
            "short_code": row[0],
            "short_url": f"{BASE_URL}/{row[0]}",
            "original_url": row[1],
            "title": row[2],
            "click_count": row[3],
            "created_at": row[4]
        })
    
    conn.close()
    
    return jsonify({
        "success": True,
        "links": links,
        "pagination": {
            "page": page,
            "limit": limit,
            "total": total,
            "pages": (total + limit - 1) // limit
        }
    })

@app.route('/api/stats/<short_code>', methods=['GET'])
def get_stats(short_code):
    """获取链接统计"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    # 获取链接信息
    cursor.execute(
        "SELECT original_url, title, click_count, created_at FROM links WHERE short_code = ?",
        (short_code,)
    )
    link = cursor.fetchone()
    
    if not link:
        conn.close()
        return jsonify({"error": "Short link not found"}), 404
    
    # 获取点击记录
    cursor.execute(
        "SELECT ip_address, user_agent, clicked_at FROM clicks WHERE short_code = ? ORDER BY clicked_at DESC LIMIT 100",
        (short_code,)
    )
    clicks = cursor.fetchall()
    
    conn.close()
    
    return jsonify({
        "success": True,
        "short_code": short_code,
        "short_url": f"{BASE_URL}/{short_code}",
        "original_url": link[0],
        "title": link[1],
        "click_count": link[2],
        "created_at": link[3],
        "recent_clicks": [
            {
                "ip_address": click[0],
                "user_agent": click[1],
                "clicked_at": click[2]
            } for click in clicks
        ]
    })

@app.route('/api/delete/<short_code>', methods=['DELETE'])
def delete_link(short_code):
    """删除短链接"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    cursor.execute("DELETE FROM clicks WHERE short_code = ?", (short_code,))
    cursor.execute("DELETE FROM links WHERE short_code = ?", (short_code,))
    
    if cursor.rowcount == 0:
        conn.close()
        return jsonify({"error": "Short link not found"}), 404
    
    conn.commit()
    conn.close()
    
    return jsonify({"success": True, "message": "Short link deleted"})

@app.route('/<short_code>')
def redirect_link(short_code):
    """短链接重定向"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    cursor.execute("SELECT original_url FROM links WHERE short_code = ?", (short_code,))
    result = cursor.fetchone()
    
    if not result:
        conn.close()
        return jsonify({"error": "Short link not found"}), 404
    
    original_url = result[0]
    
    # 记录点击
    ip_address = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR'))
    user_agent = request.headers.get('User-Agent', '')
    
    cursor.execute(
        "INSERT INTO clicks (short_code, ip_address, user_agent) VALUES (?, ?, ?)",
        (short_code, ip_address, user_agent)
    )
    
    # 更新点击计数
    cursor.execute(
        "UPDATE links SET click_count = click_count + 1 WHERE short_code = ?",
        (short_code,)
    )
    
    conn.commit()
    conn.close()
    
    return redirect(original_url)

@app.route('/health')
def health_check():
    """健康检查"""
    return jsonify({"status": "ok", "timestamp": datetime.now().isoformat()})

@app.route('/')
def index():
    """API文档"""
    return jsonify({
        "name": "Simple Short Link API",
        "version": "1.0.0",
        "endpoints": {
            "POST /api/create": "Create short link",
            "GET /api/list": "List all links",
            "GET /api/stats/<code>": "Get link statistics",
            "DELETE /api/delete/<code>": "Delete short link",
            "GET /<code>": "Redirect to original URL",
            "GET /health": "Health check"
        },
        "authentication": "Authorization header required",
        "example": {
            "create": {
                "url": "POST /api/create",
                "headers": {"Authorization": "TaDeixjf9alwtJe5v4wv7F7cIpXM03hl", "Content-Type": "application/json"},
                "body": {"url": "https://www.example.com", "title": "Example", "code": "custom"}
            }
        }
    })

if __name__ == '__main__':
    # 初始化数据库
    init_db()
    
    # 启动服务
    print("🚀 Starting Simple Short Link API...")
    print(f"📡 Server: http://localhost:2282")
    print(f"🔑 Authorization: {API_TOKEN}")
    print(f"📚 API Docs: http://localhost:2282")
    
    app.run(host='0.0.0.0', port=2282, debug=False)
