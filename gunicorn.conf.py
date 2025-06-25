# Gunicorn配置文件
import multiprocessing
import os

# 服务器套接字
bind = "0.0.0.0:2282"
backlog = 2048

# 工作进程
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "gevent"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 50
preload_app = True
timeout = 30
keepalive = 2

# 日志
accesslog = "/app/logs/gunicorn_access.log"
errorlog = "/app/logs/gunicorn_error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# 进程命名
proc_name = "shortlink-api"

# 安全
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# 性能
worker_tmp_dir = "/dev/shm"
tmp_upload_dir = None

# 重启
max_requests = 1000
max_requests_jitter = 100

# 用户和组
user = os.getenv('APP_USER', 'www-data')
group = os.getenv('APP_GROUP', 'www-data')

# 守护进程
daemon = False
pidfile = "/app/gunicorn.pid"

# 环境变量
raw_env = [
    f'API_TOKEN={os.getenv("API_TOKEN", "")}',
    f'BASE_URL={os.getenv("BASE_URL", "http://localhost:2282")}',
    f'SHORT_CODE_LENGTH={os.getenv("SHORT_CODE_LENGTH", "6")}',
    f'LOG_LEVEL={os.getenv("LOG_LEVEL", "INFO")}',
]
