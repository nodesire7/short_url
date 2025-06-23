#!/bin/bash

# Jump Jump 数据备份脚本
# 定期备份Redis数据，确保数据安全

set -e

# 配置
BACKUP_DIR="./backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="jumpjump_backup_$DATE"

echo "💾 开始备份 Jump Jump 数据..."

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 检查服务状态
if ! docker-compose ps | grep -q "jumpjump-redis.*Up"; then
    echo "❌ 错误: Redis服务未运行"
    exit 1
fi

echo "📦 创建备份: $BACKUP_NAME"

# 创建备份目录
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
mkdir -p "$BACKUP_PATH"

# 备份Redis数据
echo "🔄 备份Redis数据..."
docker-compose exec -T db redis-cli BGSAVE
sleep 2

# 等待备份完成
while docker-compose exec -T db redis-cli LASTSAVE | grep -q $(docker-compose exec -T db redis-cli LASTSAVE); do
    echo "⏳ 等待Redis备份完成..."
    sleep 1
done

# 复制数据文件
echo "📁 复制数据文件..."
cp -r ./data/redis/* "$BACKUP_PATH/" 2>/dev/null || true

# 备份配置文件
echo "⚙️ 备份配置文件..."
cp docker-compose.yaml "$BACKUP_PATH/"
cp config/redis.conf "$BACKUP_PATH/"

# 创建备份信息文件
cat > "$BACKUP_PATH/backup_info.txt" << EOF
Jump Jump 备份信息
==================

备份时间: $(date)
备份版本: $BACKUP_NAME
服务状态:
$(docker-compose ps)

Redis信息:
$(docker-compose exec -T db redis-cli INFO server | head -10)

数据统计:
$(docker-compose exec -T db redis-cli INFO keyspace)
EOF

# 压缩备份
echo "🗜️ 压缩备份文件..."
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"
cd ..

# 清理旧备份（保留最近7天）
echo "🧹 清理旧备份..."
find "$BACKUP_DIR" -name "jumpjump_backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true

echo ""
echo "✅ 备份完成！"
echo "📁 备份文件: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo "📊 备份大小: $(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)"
echo ""
echo "💡 恢复备份:"
echo "   1. 停止服务: docker-compose down"
echo "   2. 解压备份: tar -xzf $BACKUP_DIR/${BACKUP_NAME}.tar.gz -C $BACKUP_DIR"
echo "   3. 恢复数据: cp -r $BACKUP_DIR/$BACKUP_NAME/* ./data/redis/"
echo "   4. 启动服务: ./start.sh"
echo ""
