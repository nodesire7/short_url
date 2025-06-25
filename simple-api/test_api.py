#!/usr/bin/env python3
"""
短链接API测试脚本
"""

import requests
import json
import time

# 配置
BASE_URL = "http://localhost:2282"
API_TOKEN = "TaDeixjf9alwtJe5v4wv7F7cIpXM03hl"

headers = {
    "Authorization": API_TOKEN,
    "Content-Type": "application/json"
}

def test_health():
    """测试健康检查"""
    print("🔍 测试健康检查...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.json()}")
    print()

def test_create_link():
    """测试创建短链接"""
    print("📝 测试创建短链接...")
    
    # 测试1: 基本创建
    data = {
        "url": "https://www.google.com",
        "title": "Google搜索"
    }
    response = requests.post(f"{BASE_URL}/api/create", headers=headers, json=data)
    print(f"创建链接 - 状态码: {response.status_code}")
    result = response.json()
    print(f"响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
    
    if response.status_code == 201:
        short_code = result['short_code']
        print(f"✅ 创建成功，短代码: {short_code}")
        return short_code
    else:
        print("❌ 创建失败")
        return None
    print()

def test_create_custom_link():
    """测试创建自定义短链接"""
    print("🎯 测试创建自定义短链接...")
    
    data = {
        "url": "https://github.com",
        "title": "GitHub",
        "code": "github"
    }
    response = requests.post(f"{BASE_URL}/api/create", headers=headers, json=data)
    print(f"创建自定义链接 - 状态码: {response.status_code}")
    result = response.json()
    print(f"响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
    print()
    return "github" if response.status_code == 201 else None

def test_list_links():
    """测试获取链接列表"""
    print("📋 测试获取链接列表...")
    response = requests.get(f"{BASE_URL}/api/list", headers=headers)
    print(f"获取列表 - 状态码: {response.status_code}")
    result = response.json()
    print(f"链接数量: {len(result.get('links', []))}")
    print(f"分页信息: {result.get('pagination', {})}")
    print()

def test_redirect(short_code):
    """测试短链接重定向"""
    if not short_code:
        return
        
    print(f"🔗 测试短链接重定向: {short_code}")
    response = requests.get(f"{BASE_URL}/{short_code}", allow_redirects=False)
    print(f"重定向 - 状态码: {response.status_code}")
    if response.status_code == 302:
        print(f"重定向到: {response.headers.get('Location')}")
        print("✅ 重定向成功")
    else:
        print("❌ 重定向失败")
    print()

def test_stats(short_code):
    """测试获取统计信息"""
    if not short_code:
        return
        
    print(f"📊 测试获取统计信息: {short_code}")
    response = requests.get(f"{BASE_URL}/api/stats/{short_code}", headers=headers)
    print(f"获取统计 - 状态码: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print(f"点击次数: {result.get('click_count', 0)}")
        print(f"最近点击: {len(result.get('recent_clicks', []))} 条记录")
        print("✅ 获取统计成功")
    else:
        print("❌ 获取统计失败")
    print()

def test_delete(short_code):
    """测试删除短链接"""
    if not short_code:
        return
        
    print(f"🗑️  测试删除短链接: {short_code}")
    response = requests.delete(f"{BASE_URL}/api/delete/{short_code}", headers=headers)
    print(f"删除链接 - 状态码: {response.status_code}")
    if response.status_code == 200:
        print("✅ 删除成功")
    else:
        print("❌ 删除失败")
    print()

def test_unauthorized():
    """测试未授权访问"""
    print("🚫 测试未授权访问...")
    bad_headers = {"Content-Type": "application/json"}
    response = requests.get(f"{BASE_URL}/api/list", headers=bad_headers)
    print(f"未授权访问 - 状态码: {response.status_code}")
    if response.status_code == 401:
        print("✅ 正确拒绝未授权访问")
    else:
        print("❌ 授权验证有问题")
    print()

def main():
    """主测试函数"""
    print("🚀 开始测试短链接API")
    print("=" * 50)
    
    try:
        # 基础测试
        test_health()
        test_unauthorized()
        
        # 功能测试
        short_code1 = test_create_link()
        short_code2 = test_create_custom_link()
        
        test_list_links()
        
        # 访问测试
        test_redirect(short_code1)
        test_redirect(short_code2)
        
        # 等待一下让统计更新
        time.sleep(1)
        
        # 统计测试
        test_stats(short_code1)
        test_stats(short_code2)
        
        # 清理测试
        # test_delete(short_code1)  # 可选：删除测试数据
        
        print("✅ 所有测试完成！")
        
    except requests.exceptions.ConnectionError:
        print("❌ 无法连接到API服务，请确保服务已启动在 http://localhost:2282")
    except Exception as e:
        print(f"❌ 测试过程中出现错误: {e}")

if __name__ == "__main__":
    main()
