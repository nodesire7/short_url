#!/usr/bin/env python3
"""
生产级短链接API服务
使用Gunicorn + Nginx部署
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
import logging
from logging.handlers import RotatingFileHandler
import threading
import time

app = Flask(__name__)

# 配置
API_TOKEN = os.getenv('API_TOKEN')
if not API_TOKEN:
    raise ValueError("API_TOKEN environment variable is required")
DATABASE = os.getenv('DATABASE_PATH', '/app/data/shortlinks.db')
BASE_URL = os.getenv('BASE_URL', 'http://localhost:2282')
SHORT_CODE_LENGTH = int(os.getenv('SHORT_CODE_LENGTH', '6'))
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')

# 确保数据目录存在并设置权限
data_dir = '/app/data'
logs_dir = '/app/logs'

os.makedirs(data_dir, exist_ok=True)
os.makedirs(logs_dir, exist_ok=True)

# 确保目录权限正确
try:
    os.chmod(data_dir, 0o755)
    os.chmod(logs_dir, 0o755)
except PermissionError:
    pass  # 在某些环境中可能没有权限修改

# 配置日志
def setup_logging():
    """配置日志系统"""
    log_formatter = logging.Formatter(
        '%(asctime)s %(levelname)s [%(name)s] [%(filename)s:%(lineno)d] %(message)s'
    )
    
    # 文件日志处理器
    file_handler = RotatingFileHandler(
        '/app/logs/app.log', 
        maxBytes=50*1024*1024,  # 50MB
        backupCount=10
    )
    file_handler.setFormatter(log_formatter)
    file_handler.setLevel(getattr(logging, LOG_LEVEL))
    
    # 访问日志处理器
    access_handler = RotatingFileHandler(
        '/app/logs/access.log',
        maxBytes=50*1024*1024,  # 50MB
        backupCount=10
    )
    access_handler.setFormatter(logging.Formatter(
        '%(asctime)s %(message)s'
    ))
    
    # 配置应用日志
    app.logger.addHandler(file_handler)
    app.logger.setLevel(getattr(logging, LOG_LEVEL))
    
    # 配置访问日志
    access_logger = logging.getLogger('access')
    access_logger.addHandler(access_handler)
    access_logger.setLevel(logging.INFO)
    
    return access_logger

access_logger = setup_logging()

# 数据库连接池
class DatabasePool:
    def __init__(self, database_path, pool_size=10):
        self.database_path = database_path
        self.pool_size = pool_size
        self.connections = []
        self.lock = threading.Lock()
        self._init_pool()
    
    def _init_pool(self):
        """初始化连接池"""
        for _ in range(self.pool_size):
            conn = sqlite3.connect(self.database_path, check_same_thread=False)
            conn.row_factory = sqlite3.Row
            self.connections.append(conn)
    
    def get_connection(self):
        """获取数据库连接"""
        with self.lock:
            if self.connections:
                return self.connections.pop()
            else:
                # 如果池中没有连接，创建新连接
                conn = sqlite3.connect(self.database_path, check_same_thread=False)
                conn.row_factory = sqlite3.Row
                return conn
    
    def return_connection(self, conn):
        """归还数据库连接"""
        with self.lock:
            if len(self.connections) < self.pool_size:
                self.connections.append(conn)
            else:
                conn.close()

# 数据库连接池（延迟初始化）
db_pool = None

def get_db_pool():
    """获取数据库连接池，延迟初始化"""
    global db_pool, DATABASE
    if db_pool is None:
        # 尝试多个数据库路径
        db_paths = [
            DATABASE,  # 原始路径
            "/tmp/shortlinks.db",  # 临时目录
            "./shortlinks.db",  # 当前目录
            ":memory:"  # 内存数据库（最后备选）
        ]

        working_db_path = None

        for db_path in db_paths:
            try:
                if db_path == ":memory:":
                    # 内存数据库总是可用
                    working_db_path = db_path
                    app.logger.warning("Using in-memory database as fallback")
                    break

                # 确保目录存在
                db_dir = os.path.dirname(db_path)
                if db_dir and not os.path.exists(db_dir):
                    os.makedirs(db_dir, mode=0o755, exist_ok=True)

                # 测试数据库文件创建权限
                test_conn = sqlite3.connect(db_path)
                test_conn.execute("SELECT 1")
                test_conn.close()

                working_db_path = db_path
                app.logger.info(f"Database file accessible: {db_path}")
                break

            except (sqlite3.OperationalError, PermissionError, OSError) as e:
                app.logger.warning(f"Cannot use database path {db_path}: {e}")
                continue

        if working_db_path is None:
            working_db_path = ":memory:"
            app.logger.error("All database paths failed, using in-memory database")

        DATABASE = working_db_path
        db_pool = DatabasePool(DATABASE)
    return db_pool

def init_db():
    """初始化数据库"""
    pool = get_db_pool()
    conn = pool.get_connection()
    try:
        cursor = conn.cursor()
        
        # 创建链接表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS links (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                short_code TEXT UNIQUE NOT NULL,
                original_url TEXT NOT NULL,
                title TEXT,
                click_count INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # 创建点击记录表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS clicks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                short_code TEXT NOT NULL,
                ip_address TEXT,
                user_agent TEXT,
                referer TEXT,
                clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (short_code) REFERENCES links (short_code)
            )
        ''')
        
        # 创建索引
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_links_short_code ON links(short_code)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_clicks_short_code ON clicks(short_code)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_clicks_clicked_at ON clicks(clicked_at)')
        
        conn.commit()
        app.logger.info('Database initialized successfully')
        
    except Exception as e:
        app.logger.error(f'Database initialization failed: {str(e)}')
        raise
    finally:
        pool.return_connection(conn)

def verify_auth():
    """验证Authorization"""
    auth_header = request.headers.get('Authorization')
    if not auth_header or auth_header != API_TOKEN:
        access_logger.info(f'Unauthorized access from {request.remote_addr}')
        return False
    return True

def generate_short_code():
    """生成短链接代码"""
    chars = string.ascii_letters + string.digits
    max_attempts = 10
    
    for _ in range(max_attempts):
        code = ''.join(random.choice(chars) for _ in range(SHORT_CODE_LENGTH))
        
        pool = get_db_pool()
        conn = pool.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT 1 FROM links WHERE short_code = ?", (code,))
            if not cursor.fetchone():
                return code
        finally:
            pool.return_connection(conn)
    
    raise Exception("Failed to generate unique short code")

def is_valid_url(url):
    """验证URL格式"""
    url_pattern = re.compile(
        r'^https?://'
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'
        r'localhost|'
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
        r'(?::\d+)?'
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)
    return url_pattern.match(url) is not None

# 请求日志中间件
@app.before_request
def log_request():
    """记录请求日志"""
    access_logger.info(
        f'{request.remote_addr} - "{request.method} {request.path}" '
        f'User-Agent: "{request.headers.get("User-Agent", "")}" '
        f'Authorization: "{request.headers.get("Authorization", "")[:20]}..." '
        f'Content-Type: "{request.headers.get("Content-Type", "")}"'
    )

@app.after_request
def log_response(response):
    """记录响应日志"""
    access_logger.info(
        f'{request.remote_addr} - "{request.method} {request.path}" '
        f'{response.status_code} {response.content_length or 0}'
    )

    # 添加CORS头
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'

    return response

# 处理OPTIONS请求
@app.route('/api/<path:path>', methods=['OPTIONS'])
def handle_options(path):
    """处理预检请求"""
    response = jsonify({'status': 'ok'})
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    return response

@app.route('/api/create', methods=['POST'])
def create_short_link():
    """创建短链接"""
    app.logger.info(f"Create request: {request.method} {request.path}")
    app.logger.info(f"Headers: {dict(request.headers)}")
    app.logger.info(f"Content-Type: {request.content_type}")

    if not verify_auth():
        app.logger.warning("Unauthorized access attempt")
        return jsonify({"error": "Unauthorized"}), 401

    try:
        # 获取原始数据用于调试
        raw_data = request.get_data()
        app.logger.info(f"Raw request data: {raw_data}")

        data = request.get_json()
        app.logger.info(f"Parsed JSON data: {data}")

        if not data:
            app.logger.error("No JSON data received")
            return jsonify({"error": "Invalid JSON"}), 400
        
        original_url = data.get('url')
        custom_code = data.get('code')
        title = data.get('title', '')
        
        if not original_url:
            return jsonify({"error": "URL is required"}), 400
        
        if not is_valid_url(original_url):
            return jsonify({"error": "Invalid URL format"}), 400
        
        # 验证自定义代码
        if custom_code:
            if len(custom_code) < 3 or len(custom_code) > 20:
                return jsonify({"error": "Custom code must be 3-20 characters"}), 400
            if not re.match(r'^[a-zA-Z0-9_-]+$', custom_code):
                return jsonify({"error": "Custom code can only contain letters, numbers, _ and -"}), 400
            short_code = custom_code
        else:
            short_code = generate_short_code()
        
        # 保存到数据库
        conn = db_pool.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO links (short_code, original_url, title) VALUES (?, ?, ?)",
                (short_code, original_url, title)
            )
            conn.commit()
            
            app.logger.info(f'Created short link: {short_code} -> {original_url}')
            
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
        finally:
            db_pool.return_connection(conn)
            
    except Exception as e:
        app.logger.error(f'Error creating short link: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/list', methods=['GET'])
def list_links():
    """获取链接列表"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        page = max(1, int(request.args.get('page', 1)))
        limit = min(100, max(1, int(request.args.get('limit', 20))))
        offset = (page - 1) * limit
        
        conn = db_pool.get_connection()
        try:
            cursor = conn.cursor()
            
            # 获取总数
            cursor.execute("SELECT COUNT(*) FROM links")
            total = cursor.fetchone()[0]
            
            # 获取链接列表
            cursor.execute(
                "SELECT short_code, original_url, title, click_count, created_at FROM links "
                "ORDER BY created_at DESC LIMIT ? OFFSET ?",
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
            
        finally:
            db_pool.return_connection(conn)
            
    except Exception as e:
        app.logger.error(f'Error listing links: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/stats/<short_code>', methods=['GET'])
def get_stats(short_code):
    """获取链接统计"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        conn = db_pool.get_connection()
        try:
            cursor = conn.cursor()
            
            # 获取链接信息
            cursor.execute(
                "SELECT original_url, title, click_count, created_at FROM links WHERE short_code = ?",
                (short_code,)
            )
            link = cursor.fetchone()
            
            if not link:
                return jsonify({"error": "Short link not found"}), 404
            
            # 获取最近点击记录
            cursor.execute(
                "SELECT ip_address, user_agent, referer, clicked_at FROM clicks "
                "WHERE short_code = ? ORDER BY clicked_at DESC LIMIT 100",
                (short_code,)
            )
            clicks = cursor.fetchall()
            
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
                        "referer": click[2],
                        "clicked_at": click[3]
                    } for click in clicks
                ]
            })
            
        finally:
            db_pool.return_connection(conn)
            
    except Exception as e:
        app.logger.error(f'Error getting stats for {short_code}: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/delete/<short_code>', methods=['DELETE'])
def delete_link(short_code):
    """删除短链接"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        conn = db_pool.get_connection()
        try:
            cursor = conn.cursor()
            
            # 删除点击记录
            cursor.execute("DELETE FROM clicks WHERE short_code = ?", (short_code,))
            
            # 删除链接
            cursor.execute("DELETE FROM links WHERE short_code = ?", (short_code,))
            
            if cursor.rowcount == 0:
                return jsonify({"error": "Short link not found"}), 404
            
            conn.commit()
            app.logger.info(f'Deleted short link: {short_code}')
            
            return jsonify({"success": True, "message": "Short link deleted"})
            
        finally:
            db_pool.return_connection(conn)
            
    except Exception as e:
        app.logger.error(f'Error deleting link {short_code}: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/<short_code>')
def redirect_link(short_code):
    """短链接重定向"""
    try:
        conn = db_pool.get_connection()
        try:
            cursor = conn.cursor()
            
            # 获取原始URL
            cursor.execute("SELECT original_url FROM links WHERE short_code = ?", (short_code,))
            result = cursor.fetchone()
            
            if not result:
                return jsonify({"error": "Short link not found"}), 404
            
            original_url = result[0]
            
            # 记录点击
            ip_address = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR'))
            user_agent = request.headers.get('User-Agent', '')
            referer = request.headers.get('Referer', '')
            
            cursor.execute(
                "INSERT INTO clicks (short_code, ip_address, user_agent, referer) VALUES (?, ?, ?, ?)",
                (short_code, ip_address, user_agent, referer)
            )
            
            # 更新点击计数
            cursor.execute(
                "UPDATE links SET click_count = click_count + 1, updated_at = CURRENT_TIMESTAMP WHERE short_code = ?",
                (short_code,)
            )
            
            conn.commit()
            
            app.logger.info(f'Redirected {short_code} -> {original_url} from {ip_address}')
            
            return redirect(original_url)
            
        finally:
            db_pool.return_connection(conn)
            
    except Exception as e:
        app.logger.error(f'Error redirecting {short_code}: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/health')
def health_check():
    """健康检查"""
    try:
        # 检查数据库连接
        conn = db_pool.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            db_status = "ok"
        except Exception:
            db_status = "error"
        finally:
            db_pool.return_connection(conn)
        
        return jsonify({
            "status": "ok",
            "timestamp": datetime.now().isoformat(),
            "database": db_status,
            "version": "1.0.0"
        })
    except Exception as e:
        app.logger.error(f'Health check failed: {str(e)}')
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/')
def index():
    """API文档"""
    return jsonify({
        "name": "Production Short Link API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "POST /api/create": "Create short link",
            "GET /api/list": "List all links",
            "GET /api/stats/<code>": "Get link statistics",
            "DELETE /api/delete/<code>": "Delete short link",
            "GET /<code>": "Redirect to original URL",
            "GET /health": "Health check"
        },
        "authentication": "Authorization header required",
        "documentation": "https://github.com/your-repo/shortlink-api"
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    app.logger.error(f'Internal server error: {str(error)}')
    return jsonify({"error": "Internal server error"}), 500

# 初始化数据库
init_db()

if __name__ == '__main__':
    app.logger.info('Short Link API starting in development mode...')
    app.run(host='0.0.0.0', port=2282, debug=False)
