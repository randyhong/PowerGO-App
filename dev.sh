#!/bin/bash

# PowerGo 开发环境启动脚本

echo "🚀 PowerGo 开发环境启动器"
echo "=========================="
echo
echo "请选择运行平台："
echo "1) Web (Chrome) - 推荐，最快启动"
echo "2) macOS 桌面应用"
echo "3) Android 模拟器"
echo "4) iOS 模拟器"
echo "5) 查看可用设备"
echo "6) 构建APK"
echo "7) 代码分析"
echo "0) 退出"
echo

read -p "请输入选项 (1-7): " choice

case $choice in
  1)
    echo "🌐 启动Web版本..."
    flutter run -d chrome --web-port 3000
    ;;
  2)
    echo "🖥️ 启动macOS版本..."
    flutter run -d macos
    ;;
  3)
    echo "🤖 启动Android模拟器..."
    flutter run -d android
    ;;
  4)
    echo "📱 启动iOS模拟器..."
    flutter run -d ios
    ;;
  5)
    echo "📋 可用设备列表："
    flutter devices
    ;;
  6)
    echo "📦 构建APK..."
    flutter build apk --release
    echo "✅ APK已生成: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  7)
    echo "🔍 代码分析..."
    flutter analyze
    ;;
  0)
    echo "👋 再见！"
    exit 0
    ;;
  *)
    echo "❌ 无效选项，请重新运行脚本"
    exit 1
    ;;
esac