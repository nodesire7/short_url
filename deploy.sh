#!/bin/bash

# 生产级短链接API服务一键部署脚本
# 支持Docker和Systemd两种部署方式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}📡 $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查系统要求
check_requirements() {
    print_info "检查系统要求..."

    # 检查操作系统
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "此脚本仅支持Linux系统"
        exit 1
    fi

    # 检查权限
    if [[ $EUID -ne 0 ]]; then
        print_warning "建议使用root权限运行此脚本"
    fi

    print_success "系统要求检查通过"
}

# 设置环境变量
setup_environment() {
    print_info "配置环境变量..."

    # 检查是否存在.env文件
    if [ ! -f ".env" ]; then
        print_warning ".env文件不存在，创建默认配置..."

        # 生成随机API Token
        API_TOKEN=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p -c 32)

        cat > .env << EOF
# 短链接API配置
API_TOKEN=${API_TOKEN}
BASE_URL=http://localhost:2282
SHORT_CODE_LENGTH=6
LOG_LEVEL=INFO
EOF
        print_success "已创建.env文件，请根据需要修改配置"
        print_warning "API_TOKEN: ${API_TOKEN}"
    else
        print_success "使用现有.env配置文件"
    fi

    # 加载环境变量
    if [ -f ".env" ]; then
        export $(cat .env | grep -v '^#' | xargs)
        print_success "环境变量加载完成"
    fi

    # 验证必需的环境变量
    if [ -z "$API_TOKEN" ]; then
        print_error "API_TOKEN未设置，请在.env文件中配置"
        exit 1
    fi
}

# Docker部署
deploy_docker() {
    print_info "使用Docker部署..."

    # 检查Docker
    if ! command -v docker &> /dev/null; then
        print_info "安装Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
    fi

    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_info "安装Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

    # 创建目录
    mkdir -p data logs

    # 验证环境变量
    if [ -z "$API_TOKEN" ]; then
        print_error "API_TOKEN未设置，请先运行环境配置"
        exit 1
    fi

    # 构建并启动服务
    print_info "构建并启动服务..."
    docker-compose up -d --build
    
    # 等待服务启动
    print_info "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    if docker-compose ps | grep -q "Up"; then
        print_success "Docker部署成功！"
        print_info "服务地址: http://localhost:2282"
        print_info "Nginx代理: http://localhost:80"
        print_info "认证令牌: $API_TOKEN"
        
        # 显示管理命令
        echo ""
        print_info "管理命令:"
        echo "  docker-compose ps          # 查看服务状态"
        echo "  docker-compose logs -f     # 查看日志"
        echo "  docker-compose restart     # 重启服务"
        echo "  docker-compose down        # 停止服务"
    else
        print_error "Docker部署失败"
        docker-compose logs
        exit 1
    fi
}

# Systemd部署
deploy_systemd() {
    print_info "使用Systemd部署..."
    
    # 检查Python
    if ! command -v python3 &> /dev/null; then
        print_info "安装Python3..."
        apt-get update
        apt-get install -y python3 python3-pip python3-venv
    fi
    
    # 检查Nginx
    if ! command -v nginx &> /dev/null; then
        print_info "安装Nginx..."
        apt-get update
        apt-get install -y nginx
    fi
    
    # 创建应用目录
    APP_DIR="/opt/shortlink-api"
    print_info "创建应用目录: $APP_DIR"
    mkdir -p "$APP_DIR"
    cd "$APP_DIR"
    
    # 复制应用文件
    cp app.py requirements.txt gunicorn.conf.py "$APP_DIR/"
    
    # 创建虚拟环境
    print_info "创建Python虚拟环境..."
    python3 -m venv venv
    source venv/bin/activate
    
    # 安装依赖
    print_info "安装Python依赖..."
    pip install -r requirements.txt
    
    # 创建数据和日志目录
    mkdir -p data logs

    # 创建环境变量文件
    cp .env "$APP_DIR/"

    chown -R www-data:www-data "$APP_DIR"
    
    # 配置Systemd服务
    print_info "配置Systemd服务..."
    cp systemd/shortlink-api.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable shortlink-api
    systemctl start shortlink-api
    
    # 配置Nginx
    print_info "配置Nginx..."
    cp nginx.conf /etc/nginx/sites-available/shortlink-api
    ln -sf /etc/nginx/sites-available/shortlink-api /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx
    
    # 检查服务状态
    sleep 5
    if systemctl is-active --quiet shortlink-api; then
        print_success "Systemd部署成功！"
        print_info "服务地址: http://localhost:2282"
        print_info "Nginx代理: http://localhost:80"
        print_info "认证令牌: $API_TOKEN"
        
        # 显示管理命令
        echo ""
        print_info "管理命令:"
        echo "  systemctl status shortlink-api    # 查看服务状态"
        echo "  systemctl restart shortlink-api   # 重启服务"
        echo "  systemctl stop shortlink-api      # 停止服务"
        echo "  journalctl -u shortlink-api -f    # 查看日志"
    else
        print_error "Systemd部署失败"
        systemctl status shortlink-api
        exit 1
    fi
}

# 性能优化
optimize_system() {
    print_info "应用系统优化..."
    
    # 优化内核参数
    cat >> /etc/sysctl.conf << EOF

# 短链接API优化
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_tw_buckets = 5000
EOF
    
    sysctl -p
    
    # 优化文件描述符限制
    cat >> /etc/security/limits.conf << EOF

# 短链接API优化
* soft nofile 65535
* hard nofile 65535
EOF
    
    print_success "系统优化完成"
}

# 安全加固
security_hardening() {
    print_info "应用安全加固..."
    
    # 配置防火墙
    if command -v ufw &> /dev/null; then
        ufw --force enable
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 2282/tcp
        print_success "防火墙配置完成"
    fi
    
    # 配置fail2ban
    if command -v fail2ban-server &> /dev/null; then
        cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/shortlink_error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/shortlink_error.log
maxretry = 10
EOF
        systemctl restart fail2ban
        print_success "Fail2ban配置完成"
    fi
}

# 测试API
test_api() {
    print_info "测试API功能..."
    
    # 等待服务完全启动
    sleep 5
    
    # 测试健康检查
    if curl -f http://localhost:2282/health &> /dev/null; then
        print_success "健康检查通过"
    else
        print_error "健康检查失败"
        return 1
    fi
    
    # 测试创建短链接
    RESPONSE=$(curl -s -X POST http://localhost:2282/api/create \
        -H "Authorization: $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"url": "https://www.google.com", "title": "Google"}')
    
    if echo "$RESPONSE" | grep -q "success"; then
        print_success "API功能测试通过"
        SHORT_CODE=$(echo "$RESPONSE" | grep -o '"short_code":"[^"]*"' | cut -d'"' -f4)
        print_info "测试短链接: http://localhost:2282/$SHORT_CODE"
    else
        print_error "API功能测试失败"
        echo "$RESPONSE"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "生产级短链接API服务部署脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  docker     使用Docker部署 (推荐)"
    echo "  systemd    使用Systemd部署"
    echo "  optimize   系统性能优化"
    echo "  security   安全加固"
    echo "  test       测试API功能"
    echo "  help       显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 docker              # Docker部署"
    echo "  $0 systemd optimize    # Systemd部署并优化"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}🚀 生产级短链接API服务部署${NC}"
    echo "=" * 50
    
    check_requirements
    
    # 设置环境变量
    setup_environment

    case "${1:-docker}" in
        docker)
            deploy_docker
            if [[ "$2" == "optimize" ]]; then
                optimize_system
            fi
            if [[ "$2" == "security" || "$3" == "security" ]]; then
                security_hardening
            fi
            test_api
            ;;
        systemd)
            deploy_systemd
            if [[ "$2" == "optimize" ]]; then
                optimize_system
            fi
            if [[ "$2" == "security" || "$3" == "security" ]]; then
                security_hardening
            fi
            test_api
            ;;
        optimize)
            optimize_system
            ;;
        security)
            security_hardening
            ;;
        test)
            test_api
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
    
    print_success "部署完成！"
}

# 执行主函数
main "$@"
