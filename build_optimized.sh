#!/bin/bash

# PowerGo APK体积优化构建脚本
# 用于生成最小化的发布版本APK

echo "🚀 PowerGo APK体积优化构建"
echo "=========================="

# 清理之前的构建
echo "🧹 清理构建缓存..."
flutter clean
flutter pub get

# 生成优化的图标
echo "🎨 生成优化的应用图标..."
dart run flutter_launcher_icons

echo ""
echo "📦 开始构建优化的APK包..."
echo ""

# 构建分架构APK - 推荐用于发布
echo "📱 构建分架构APK (推荐发布方式)"
flutter build apk --release --split-per-abi

echo ""
echo "📊 APK文件大小统计:"
echo "==================="
cd build/app/outputs/flutter-apk/
ls -lh app-*-release.apk | awk '{print $9 "\t" $5}'

echo ""
echo "🎯 推荐使用的APK文件:"
echo "===================="
echo "• app-arm64-v8a-release.apk - 现代64位ARM设备 (推荐)"
echo "• app-armeabi-v7a-release.apk - 老旧32位ARM设备"
echo "• app-x86_64-release.apk - x86_64模拟器/设备"

# 构建通用APK (包含所有架构)
echo ""
echo "🔄 构建通用APK (包含所有架构，体积较大)..."
cd ../../../../
flutter build apk --release

echo ""
echo "📊 通用APK大小:"
ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $9 "\t" $5}'

echo ""
echo "✅ 构建完成！"
echo ""
echo "📋 体积优化措施总结:"
echo "===================="
echo "✅ 移除未使用的依赖 (ping_discover_network_forked)"
echo "✅ 优化应用图标 (1.4MB → 245KB)"
echo "✅ 启用资源树摇 (字体文件99.7%压缩)"
echo "✅ 分架构构建 (减少50%+体积)"
echo ""
echo "💡 建议:"
echo "• 发布时优先选择 arm64-v8a 版本 (覆盖95%+现代设备)"
echo "• 如需兼容老设备，可同时发布 armeabi-v7a 版本"
echo "• Google Play建议使用AAB格式获得更好的优化"

echo ""
echo "🔧 如需进一步优化，可考虑:"
echo "• 启用代码混淆 (需要调试ProGuard规则)"
echo "• 移除更多未使用的代码"
echo "• 使用AAB格式发布到Google Play"