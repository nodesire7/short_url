#!/usr/bin/env python3
"""
生产级短链接API服务
使用Gunicorn + Nginx部署
端口: 2282
认证: Authorization=TaDeixjf9alwtJe5v4wv7F7cIpXM03hl
"""

from flask import Flask, request, jsonify, redirect
import string
import random
import re
from datetime import datetime
import os
import logging
from logging.handlers import RotatingFileHandler
import time
from urllib.parse import quote, unquote
import base64
import io

# 数据库支持
import pymysql
import pymysql.cursors

# 缓存支持
try:
    import redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False

app = Flask(__name__)

# 配置
API_TOKEN = os.getenv('API_TOKEN')
if not API_TOKEN:
    raise ValueError("API_TOKEN environment variable is required")

# 数据库配置 - 只使用MySQL
DB_TYPE = 'mysql'

# MySQL配置
MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
MYSQL_PORT = int(os.getenv('MYSQL_PORT', '3306'))
MYSQL_USER = os.getenv('MYSQL_USER', 'shortlink')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', 'shortlink123456')
MYSQL_DATABASE = os.getenv('MYSQL_DATABASE', 'shortlink')

# Redis配置
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', '6379'))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')
REDIS_DB = int(os.getenv('REDIS_DB', '0'))

# 应用配置
BASE_URL = os.getenv('BASE_URL', 'http://localhost:2282')
SHORT_CODE_LENGTH = int(os.getenv('SHORT_CODE_LENGTH', '6'))
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
CACHE_TTL = int(os.getenv('CACHE_TTL', '3600'))  # 缓存过期时间（秒）

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

# MySQL数据库管理器
class DatabaseManager:
    def __init__(self):
        self.db_type = 'mysql'
        self.pool = None
        self.cache = None
        self._init_mysql()
        self._init_cache()

    def _init_mysql(self):
        """初始化MySQL连接配置"""
        try:
            self.config = {
                'host': MYSQL_HOST,
                'port': MYSQL_PORT,
                'user': MYSQL_USER,
                'password': MYSQL_PASSWORD,
                'database': MYSQL_DATABASE,
                'charset': 'utf8mb4',
                'cursorclass': pymysql.cursors.DictCursor,
                'autocommit': True
            }

            # 测试连接
            test_conn = pymysql.connect(**self.config)
            test_conn.close()

            app.logger.info("MySQL connection initialized")

        except Exception as e:
            app.logger.error(f"MySQL initialization failed: {e}")
            raise

    def _init_cache(self):
        """初始化Redis缓存"""
        if REDIS_AVAILABLE:
            try:
                self.cache = redis.Redis(
                    host=REDIS_HOST,
                    port=REDIS_PORT,
                    password=REDIS_PASSWORD if REDIS_PASSWORD else None,
                    db=REDIS_DB,
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_timeout=5
                )
                # 测试连接
                self.cache.ping()
                app.logger.info("Redis cache initialized")
            except Exception as e:
                app.logger.warning(f"Redis initialization failed: {e}")
                self.cache = None
        else:
            app.logger.info("Redis not available, using in-memory cache")
            self.cache = None

    def get_connection(self):
        """获取数据库连接"""
        return pymysql.connect(**self.config)

    def return_connection(self, conn):
        """归还数据库连接"""
        conn.close()

    def execute_query(self, query, params=None, fetch=False):
        """执行数据库查询"""
        conn = self.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(query, params or ())

            if fetch:
                return cursor.fetchall()
            else:
                return cursor.rowcount

        finally:
            self.return_connection(conn)

# 数据库管理器（延迟初始化）
db_manager = None

def get_db_manager():
    """获取数据库管理器，延迟初始化"""
    global db_manager
    if db_manager is None:
        db_manager = DatabaseManager()
    return db_manager

def init_db():
    """初始化MySQL数据库"""
    db = get_db_manager()

    # MySQL表结构
    tables = {
        'links': '''
            CREATE TABLE IF NOT EXISTS links (
                id INT AUTO_INCREMENT PRIMARY KEY,
                short_code VARCHAR(50) UNIQUE NOT NULL,
                original_url TEXT NOT NULL,
                title VARCHAR(500),
                click_count INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_short_code (short_code),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ''',
        'clicks': '''
            CREATE TABLE IF NOT EXISTS clicks (
                id INT AUTO_INCREMENT PRIMARY KEY,
                short_code VARCHAR(50) NOT NULL,
                ip_address VARCHAR(45),
                user_agent TEXT,
                referer TEXT,
                clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_short_code (short_code),
                INDEX idx_clicked_at (clicked_at),
                FOREIGN KEY (short_code) REFERENCES links (short_code) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        '''
    }

    try:
        # 创建表
        for table_name, create_sql in tables.items():
            db.execute_query(create_sql)

        app.logger.info('MySQL database initialized successfully')

    except Exception as e:
        app.logger.error(f'Database initialization failed: {str(e)}')
        raise

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

        db = get_db_manager()
        result = db.execute_query("SELECT 1 FROM links WHERE short_code = %s", (code,), fetch=True)

        if not result:
            return code

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

def normalize_url(url):
    """标准化URL，处理中文字符编码"""
    try:
        # 如果URL包含中文字符，进行编码
        # 分离URL的各个部分
        if '?' in url:
            base_url, query = url.split('?', 1)
        else:
            base_url, query = url, ''

        # 对路径部分进行编码，保留协议和域名
        parts = base_url.split('/')
        if len(parts) >= 3:
            # 协议://域名/路径
            protocol_domain = '/'.join(parts[:3])
            path_parts = parts[3:]

            # 对路径部分进行URL编码
            encoded_path_parts = []
            for part in path_parts:
                if part:
                    # 只对包含非ASCII字符的部分进行编码
                    try:
                        part.encode('ascii')
                        encoded_path_parts.append(part)
                    except UnicodeEncodeError:
                        encoded_path_parts.append(quote(part, safe=''))
                else:
                    encoded_path_parts.append(part)

            # 重新组装URL
            if encoded_path_parts:
                normalized_url = protocol_domain + '/' + '/'.join(encoded_path_parts)
            else:
                normalized_url = protocol_domain
        else:
            normalized_url = base_url

        # 添加查询参数
        if query:
            normalized_url += '?' + query

        return normalized_url
    except Exception as e:
        app.logger.warning(f'URL normalization failed for {url}: {e}')
        return url

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

        data = request.get_json(force=True)  # 强制解析JSON
        app.logger.info(f"Parsed JSON data: {data}")

        if not data:
            app.logger.error("No JSON data received")
            return jsonify({"error": "Invalid JSON"}), 400
        
        original_url = data.get('url')
        custom_code = data.get('code')
        title = data.get('title', '')
        
        if not original_url:
            return jsonify({"error": "URL is required"}), 400
        
        # 标准化URL（处理中文字符）
        original_url = normalize_url(original_url)

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
        db = get_db_manager()

        result = db.execute_query(
            "INSERT INTO links (short_code, original_url, title) VALUES (%s, %s, %s)",
            (short_code, original_url, title)
        )

        if result:
            app.logger.info(f'Created short link: {short_code} -> {original_url}')

            return jsonify({
                "success": True,
                "short_code": short_code,
                "short_url": f"{BASE_URL}/{short_code}",
                "original_url": original_url,
                "title": title,
                "created_at": datetime.now().isoformat()
            }), 201
        else:
            return jsonify({"error": "Failed to create short link"}), 500
            
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        app.logger.error(f'Error creating short link: {str(e)}')
        app.logger.error(f'Full traceback: {error_details}')
        return jsonify({"error": "Internal server error", "details": str(e)}), 500

@app.route('/api/list', methods=['GET'])
def list_links():
    """获取链接列表"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        page = max(1, int(request.args.get('page', 1)))
        limit = min(100, max(1, int(request.args.get('limit', 20))))
        offset = (page - 1) * limit

        db = get_db_manager()

        # 获取总数
        total_result = db.execute_query("SELECT COUNT(*) as count FROM links", fetch=True)
        total = total_result[0]['count'] if total_result else 0

        # 获取链接列表
        links_result = db.execute_query(
            "SELECT short_code, original_url, title, click_count, created_at FROM links "
            "ORDER BY created_at DESC LIMIT %s OFFSET %s",
            (limit, offset), fetch=True
        )

        links = []
        if links_result:
            for row in links_result:
                links.append({
                    "short_code": row['short_code'],
                    "short_url": f"{BASE_URL}/{row['short_code']}",
                    "original_url": row['original_url'],
                    "title": row['title'],
                    "click_count": row['click_count'],
                    "created_at": str(row['created_at'])
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
            
    except Exception as e:
        app.logger.error(f'Error listing links: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/stats/<short_code>', methods=['GET'])
def get_stats(short_code):
    """获取链接统计"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        db = get_db_manager()

        # 获取链接信息
        link_result = db.execute_query(
            "SELECT original_url, title, click_count, created_at FROM links WHERE short_code = %s",
            (short_code,), fetch=True
        )
        link = link_result[0] if link_result else None

        # 获取点击记录
        clicks_result = db.execute_query(
            "SELECT ip_address, user_agent, referer, clicked_at FROM clicks "
            "WHERE short_code = %s ORDER BY clicked_at DESC LIMIT 100",
            (short_code,), fetch=True
        )

        if not link:
            return jsonify({"error": "Short link not found"}), 404

        # 处理点击记录
        recent_clicks = []
        if clicks_result:
            for click in clicks_result:
                recent_clicks.append({
                    "ip_address": click['ip_address'],
                    "user_agent": click['user_agent'],
                    "referer": click['referer'],
                    "clicked_at": str(click['clicked_at'])
                })

        return jsonify({
            "success": True,
            "short_code": short_code,
            "short_url": f"{BASE_URL}/{short_code}",
            "original_url": link['original_url'],
            "title": link['title'],
            "click_count": link['click_count'],
            "created_at": str(link['created_at']),
            "recent_clicks": recent_clicks
        })
            
    except Exception as e:
        app.logger.error(f'Error getting stats for {short_code}: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/delete/<short_code>', methods=['DELETE'])
def delete_link(short_code):
    """删除短链接"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        db = get_db_manager()

        # 删除相关的点击记录
        db.execute_query("DELETE FROM clicks WHERE short_code = %s", (short_code,))

        # 删除链接
        result = db.execute_query("DELETE FROM links WHERE short_code = %s", (short_code,))

        if result == 0:
            return jsonify({"error": "Short link not found"}), 404

        app.logger.info(f'Deleted short link: {short_code}')
        return jsonify({"success": True, "message": "Short link deleted"})
            
    except Exception as e:
        app.logger.error(f'Error deleting link {short_code}: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/<short_code>')
def redirect_link(short_code):
    """短链接重定向"""
    try:
        db = get_db_manager()

        # 获取原始URL
        result = db.execute_query("SELECT original_url FROM links WHERE short_code = %s", (short_code,), fetch=True)

        if not result:
            return jsonify({"error": "Short link not found"}), 404

        original_url = result[0]['original_url']

        # 记录点击
        ip_address = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR'))
        user_agent = request.headers.get('User-Agent', '')
        referer = request.headers.get('Referer', '')

        db.execute_query(
            "INSERT INTO clicks (short_code, ip_address, user_agent, referer) VALUES (%s, %s, %s, %s)",
            (short_code, ip_address, user_agent, referer)
        )

        # 更新点击计数
        db.execute_query(
            "UPDATE links SET click_count = click_count + 1, updated_at = CURRENT_TIMESTAMP WHERE short_code = %s",
            (short_code,)
        )

        app.logger.info(f'Redirected {short_code} -> {original_url} from {ip_address}')
        return redirect(original_url)
            
    except Exception as e:
        app.logger.error(f'Error redirecting {short_code}: {str(e)}')
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/clear', methods=['DELETE'])
def clear_all_links():
    """清空所有短链接"""
    if not verify_auth():
        return jsonify({"error": "Unauthorized"}), 401

    try:
        db = get_db_manager()

        # 获取删除前的统计
        total_result = db.execute_query("SELECT COUNT(*) as count FROM links", fetch=True)
        total_links = total_result[0]['count'] if total_result else 0

        clicks_result = db.execute_query("SELECT COUNT(*) as count FROM clicks", fetch=True)
        total_clicks = clicks_result[0]['count'] if clicks_result else 0

        # 删除所有点击记录
        db.execute_query("DELETE FROM clicks")

        # 删除所有链接
        db.execute_query("DELETE FROM links")

        app.logger.info(f'Cleared all links: {total_links} links, {total_clicks} clicks')

        return jsonify({
            "success": True,
            "message": "All links cleared successfully",
            "deleted": {
                "links": total_links,
                "clicks": total_clicks
            }
        })

    except Exception as e:
        app.logger.error(f'Error clearing links: {str(e)}')
        return jsonify({"error": "Internal server error", "details": str(e)}), 500

@app.route('/api/qr/<short_code>')
def generate_qr_code(short_code):
    """生成短链接的二维码"""
    try:
        # 检查短链接是否存在
        db = get_db_manager()
        result = db.execute_query("SELECT 1 FROM links WHERE short_code = %s", (short_code,), fetch=True)

        if not result:
            return jsonify({"error": "Short link not found"}), 404

        # 生成二维码URL
        short_url = f"{BASE_URL}/{short_code}"

        # 使用简单的二维码API服务
        qr_api_url = f"https://api.qrserver.com/v1/create-qr-code/?size=200x200&data={quote(short_url)}"

        return jsonify({
            "success": True,
            "short_code": short_code,
            "short_url": short_url,
            "qr_code_url": qr_api_url,
            "qr_code_data": short_url
        })

    except Exception as e:
        app.logger.error(f'Error generating QR code for {short_code}: {str(e)}')
        return jsonify({"error": "Internal server error", "details": str(e)}), 500

@app.route('/health')
def health_check():
    """健康检查"""
    try:
        # 检查数据库连接
        db = get_db_manager()
        try:
            db.execute_query("SELECT 1")
            db_status = "ok"
        except Exception:
            db_status = "error"
        
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
