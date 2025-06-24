# Docker Hub 自动构建配置指南

## 概述

为了让GitHub Actions自动构建并推送Docker镜像到Docker Hub，需要配置相应的认证凭据。

## 🔧 配置步骤

### 1. 创建Docker Hub访问令牌

1. **登录Docker Hub**
   - 访问：https://hub.docker.com/
   - 使用您的账号登录

2. **进入安全设置**
   - 访问：https://hub.docker.com/settings/security
   - 或点击右上角头像 → Account Settings → Security

3. **创建新的访问令牌**
   - 点击 "New Access Token" 按钮
   - 填写令牌信息：
     - **Token description**: `github-actions-shortlink`
     - **Access permissions**: `Read, Write, Delete`
   - 点击 "Generate" 生成令牌

4. **保存访问令牌**
   - ⚠️ **重要**: 复制生成的令牌并妥善保存
   - 令牌只会显示一次，关闭页面后无法再次查看

### 2. 配置GitHub Secrets

1. **进入GitHub仓库设置**
   - 访问：https://github.com/nodesire7/short_url/settings/secrets/actions
   - 或在仓库页面点击 Settings → Secrets and variables → Actions

2. **添加Repository secrets**
   
   点击 "New repository secret" 添加以下两个密钥：

   **第一个密钥：**
   - **Name**: `DOCKER_USERNAME`
   - **Secret**: `nodesire7` (您的Docker Hub用户名)

   **第二个密钥：**
   - **Name**: `DOCKER_PASSWORD`
   - **Secret**: 粘贴步骤1中生成的访问令牌

3. **验证配置**
   - 确保两个密钥都已正确添加
   - 密钥名称必须完全匹配（区分大小写）

### 3. 触发自动构建

配置完成后，以下操作会触发自动构建：

1. **推送代码到main分支**
   ```bash
   git push origin main
   ```

2. **创建版本标签**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **手动触发**
   - 在GitHub仓库页面进入 Actions 标签
   - 选择 "Build and Push Docker Images" 工作流
   - 点击 "Run workflow"

## 📊 构建状态检查

### 查看构建进度

1. **进入Actions页面**
   - 访问：https://github.com/nodesire7/short_url/actions

2. **查看工作流状态**
   - 绿色✅：构建成功
   - 红色❌：构建失败
   - 黄色🟡：构建进行中

3. **查看详细日志**
   - 点击具体的工作流运行
   - 展开各个步骤查看详细日志

### 验证镜像推送

构建成功后，可以验证镜像是否已推送：

1. **检查Docker Hub**
   - 访问：https://hub.docker.com/u/nodesire7
   - 查看是否有以下仓库：
     - `nodesire7/shortlink-backend`
     - `nodesire7/shortlink-frontend`

2. **拉取镜像测试**
   ```bash
   docker pull nodesire7/shortlink-backend:latest
   docker pull nodesire7/shortlink-frontend:latest
   ```

## 🔍 故障排除

### 常见错误

#### 1. 认证失败
```
ERROR: failed to push: push access denied, repository does not exist or may require authorization
```

**解决方案**：
- 检查Docker Hub用户名是否正确
- 确认访问令牌权限包含 Write
- 验证GitHub Secrets配置是否正确

#### 2. 仓库不存在
```
ERROR: repository does not exist
```

**解决方案**：
- 在Docker Hub上手动创建仓库：
  - `nodesire7/shortlink-backend`
  - `nodesire7/shortlink-frontend`
- 或者让Docker Hub自动创建（首次推送时）

#### 3. 令牌过期
```
ERROR: authorization failed
```

**解决方案**：
- 重新生成Docker Hub访问令牌
- 更新GitHub Secrets中的 `DOCKER_PASSWORD`

### 调试步骤

1. **检查Secrets配置**
   - 确认密钥名称正确
   - 确认密钥值没有多余的空格

2. **查看构建日志**
   - 在GitHub Actions中查看详细错误信息
   - 重点关注 "Log in to Docker Hub" 步骤

3. **手动测试**
   ```bash
   # 本地测试Docker Hub登录
   echo "YOUR_TOKEN" | docker login -u nodesire7 --password-stdin
   ```

## 🎯 最佳实践

### 安全建议

1. **使用访问令牌而非密码**
   - 访问令牌可以限制权限范围
   - 可以随时撤销而不影响其他应用

2. **定期轮换令牌**
   - 建议每6个月更换一次访问令牌
   - 及时撤销不再使用的令牌

3. **最小权限原则**
   - 只授予必要的权限（Read, Write）
   - 避免使用 Admin 权限

### 性能优化

1. **使用构建缓存**
   - GitHub Actions已配置缓存加速构建
   - 避免频繁的完整重建

2. **多架构构建**
   - 支持 AMD64 和 ARM64 架构
   - 提高镜像兼容性

## 📞 获取帮助

如果遇到问题：

1. 查看本文档的故障排除部分
2. 检查GitHub Actions的构建日志
3. 参考Docker Hub官方文档
4. 在GitHub仓库中提交Issue

---

**配置完成后，您的短链接系统将具备完全自动化的Docker镜像构建和发布能力！** 🎉
