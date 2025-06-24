#!/bin/bash

# 短链接管理系统启动脚本
# 适用于开发和生产环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${2}${1}${NC}"
}

print_success() {
    print_message "$1" "$GREEN"
}

print_error() {
    print_message "$1" "$RED"
}

print_warning() {
    print_message "$1" "$YELLOW"
}

print_info() {
    print_message "$1" "$BLUE"
}

# 检查Docker和Docker Compose
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi

    print_success "✓ Docker 环境检查通过"
}

# 检查环境变量文件
check_env_files() {
    if [ ! -f "backend/.env" ]; then
        print_warning "后端环境变量文件不存在，正在创建..."
        cp backend/.env.example backend/.env
        print_info "请编辑 backend/.env 文件配置数据库等信息"
    fi

    if [ ! -f "frontend/.env" ]; then
        print_warning "前端环境变量文件不存在，正在创建..."
        cp frontend/.env.example frontend/.env
        print_info "请编辑 frontend/.env 文件配置API地址等信息"
    fi

    print_success "✓ 环境变量文件检查完成"
}

# 启动服务
start_services() {
    print_info "正在启动短链接管理系统..."
    
    # 构建并启动服务
    docker-compose up -d --build
    
    print_success "✓ 服务启动完成"
}

# 检查服务状态
check_services() {
    print_info "检查服务状态..."
    
    # 等待服务启动
    sleep 10
    
    # 检查后端健康状态
    if curl -f http://localhost:9848/health &> /dev/null; then
        print_success "✓ 后端服务运行正常"
    else
        print_error "✗ 后端服务启动失败"
        docker-compose logs backend
        exit 1
    fi
    
    # 检查前端服务
    if curl -f http://localhost:8848 &> /dev/null; then
        print_success "✓ 前端服务运行正常"
    else
        print_error "✗ 前端服务启动失败"
        docker-compose logs frontend
        exit 1
    fi
}

# 显示访问信息
show_access_info() {
    print_success "🎉 短链接管理系统启动成功！"
    echo
    print_info "访问地址："
    echo "  前端管理界面: http://localhost:8848"
    echo "  后端API接口: http://localhost:9848"
    echo "  API文档: http://localhost:9848/docs"
    echo
    print_info "默认管理员账号："
    echo "  邮箱: admin@shortlink.com"
    echo "  密码: admin123456"
    echo
    print_warning "⚠️  请及时修改默认密码和配置信息"
    echo
    print_info "常用命令："
    echo "  查看日志: docker-compose logs -f"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart"
    echo "  查看状态: docker-compose ps"
}

# 停止服务
stop_services() {
    print_info "正在停止服务..."
    docker-compose down
    print_success "✓ 服务已停止"
}

# 重启服务
restart_services() {
    print_info "正在重启服务..."
    docker-compose restart
    print_success "✓ 服务已重启"
}

# 查看日志
show_logs() {
    docker-compose logs -f
}

# 清理数据
clean_data() {
    print_warning "⚠️  这将删除所有数据，包括数据库和上传的文件"
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "正在清理数据..."
        docker-compose down -v
        docker system prune -f
        print_success "✓ 数据清理完成"
    else
        print_info "操作已取消"
    fi
}

# 显示帮助信息
show_help() {
    echo "短链接管理系统启动脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  start     启动服务 (默认)"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  logs      查看日志"
    echo "  status    查看服务状态"
    echo "  clean     清理所有数据"
    echo "  help      显示帮助信息"
    echo
}

# 查看服务状态
show_status() {
    docker-compose ps
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            check_docker
            check_env_files
            start_services
            check_services
            show_access_info
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        clean)
            clean_data
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
}

# 执行主函数
main "$@"
