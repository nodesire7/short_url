#!/bin/bash

# 短链接管理系统 Docker 构建和推送脚本
# 使用方法: ./docker-build.sh [选项]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
DOCKER_USERNAME="${DOCKER_USERNAME:-nodesire7}"
IMAGE_PREFIX="${IMAGE_PREFIX:-$DOCKER_USERNAME}"
VERSION="${VERSION:-latest}"
PLATFORM="${PLATFORM:-linux/amd64,linux/arm64}"

# 镜像名称
BACKEND_IMAGE="$IMAGE_PREFIX/shortlink-backend"
FRONTEND_IMAGE="$IMAGE_PREFIX/shortlink-frontend"

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

# 检查Docker环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker 服务未运行，请启动 Docker"
        exit 1
    fi

    print_success "✓ Docker 环境检查通过"
}

# 检查Docker Buildx
check_buildx() {
    if ! docker buildx version &> /dev/null; then
        print_warning "Docker Buildx 未安装，将使用普通构建"
        USE_BUILDX=false
    else
        print_success "✓ Docker Buildx 可用"
        USE_BUILDX=true
    fi
}

# 登录Docker Hub
docker_login() {
    if [ -z "$DOCKER_PASSWORD" ]; then
        print_info "请输入Docker Hub密码:"
        docker login -u "$DOCKER_USERNAME"
    else
        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    fi
    
    if [ $? -eq 0 ]; then
        print_success "✓ Docker Hub 登录成功"
    else
        print_error "✗ Docker Hub 登录失败"
        exit 1
    fi
}

# 构建后端镜像
build_backend() {
    print_info "构建后端镜像: $BACKEND_IMAGE:$VERSION"
    
    if [ "$USE_BUILDX" = true ]; then
        docker buildx build \
            --platform "$PLATFORM" \
            --tag "$BACKEND_IMAGE:$VERSION" \
            --tag "$BACKEND_IMAGE:latest" \
            --push \
            ./backend
    else
        docker build \
            --tag "$BACKEND_IMAGE:$VERSION" \
            --tag "$BACKEND_IMAGE:latest" \
            ./backend
    fi
    
    if [ $? -eq 0 ]; then
        print_success "✓ 后端镜像构建成功"
    else
        print_error "✗ 后端镜像构建失败"
        exit 1
    fi
}

# 构建前端镜像
build_frontend() {
    print_info "构建前端镜像: $FRONTEND_IMAGE:$VERSION"
    
    if [ "$USE_BUILDX" = true ]; then
        docker buildx build \
            --platform "$PLATFORM" \
            --tag "$FRONTEND_IMAGE:$VERSION" \
            --tag "$FRONTEND_IMAGE:latest" \
            --push \
            ./frontend
    else
        docker build \
            --tag "$FRONTEND_IMAGE:$VERSION" \
            --tag "$FRONTEND_IMAGE:latest" \
            ./frontend
    fi
    
    if [ $? -eq 0 ]; then
        print_success "✓ 前端镜像构建成功"
    else
        print_error "✗ 前端镜像构建失败"
        exit 1
    fi
}

# 推送镜像到Docker Hub
push_images() {
    if [ "$USE_BUILDX" = true ]; then
        print_info "使用 buildx 已自动推送镜像"
        return
    fi
    
    print_info "推送镜像到 Docker Hub..."
    
    # 推送后端镜像
    docker push "$BACKEND_IMAGE:$VERSION"
    docker push "$BACKEND_IMAGE:latest"
    
    # 推送前端镜像
    docker push "$FRONTEND_IMAGE:$VERSION"
    docker push "$FRONTEND_IMAGE:latest"
    
    print_success "✓ 镜像推送完成"
}

# 创建多架构构建器
setup_buildx() {
    if [ "$USE_BUILDX" = true ]; then
        print_info "设置多架构构建器..."
        
        # 创建新的构建器实例
        docker buildx create --name shortlink-builder --use --bootstrap 2>/dev/null || true
        
        # 检查构建器状态
        docker buildx inspect --bootstrap
        
        print_success "✓ 多架构构建器设置完成"
    fi
}

# 显示镜像信息
show_images() {
    print_info "构建的镜像:"
    echo "  后端镜像: $BACKEND_IMAGE:$VERSION"
    echo "  前端镜像: $FRONTEND_IMAGE:$VERSION"
    echo
    print_info "使用方法:"
    echo "  docker pull $BACKEND_IMAGE:$VERSION"
    echo "  docker pull $FRONTEND_IMAGE:$VERSION"
    echo
    print_info "或使用 docker-compose:"
    echo "  修改 docker-compose.yml 中的镜像名称为上述镜像"
}

# 清理构建器
cleanup_buildx() {
    if [ "$USE_BUILDX" = true ]; then
        print_info "清理构建器..."
        docker buildx rm shortlink-builder 2>/dev/null || true
    fi
}

# 显示帮助信息
show_help() {
    echo "短链接管理系统 Docker 构建脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  build     构建镜像 (默认)"
    echo "  push      构建并推送镜像"
    echo "  backend   只构建后端镜像"
    echo "  frontend  只构建前端镜像"
    echo "  help      显示帮助信息"
    echo
    echo "环境变量:"
    echo "  DOCKER_USERNAME   Docker Hub 用户名 (默认: nodesire7)"
    echo "  DOCKER_PASSWORD   Docker Hub 密码"
    echo "  VERSION          镜像版本标签 (默认: latest)"
    echo "  PLATFORM         构建平台 (默认: linux/amd64,linux/arm64)"
    echo
    echo "示例:"
    echo "  $0 push                    # 构建并推送所有镜像"
    echo "  VERSION=v1.0.0 $0 push     # 构建并推送 v1.0.0 版本"
    echo "  $0 backend                 # 只构建后端镜像"
    echo
}

# 主函数
main() {
    case "${1:-build}" in
        build)
            check_docker
            check_buildx
            setup_buildx
            build_backend
            build_frontend
            cleanup_buildx
            show_images
            ;;
        push)
            check_docker
            check_buildx
            docker_login
            setup_buildx
            build_backend
            build_frontend
            push_images
            cleanup_buildx
            show_images
            ;;
        backend)
            check_docker
            check_buildx
            setup_buildx
            build_backend
            cleanup_buildx
            ;;
        frontend)
            check_docker
            check_buildx
            setup_buildx
            build_frontend
            cleanup_buildx
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

# 捕获退出信号，确保清理
trap cleanup_buildx EXIT

# 执行主函数
main "$@"
