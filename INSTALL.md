# PowerGo 开发环境安装指南

本文档详细介绍如何在本地设置PowerGo的开发环境，帮助开发者快速开始贡献代码。

## 📋 系统要求

### 必需软件
- **Flutter SDK**: 3.10.0+
- **Dart SDK**: 3.0.0+
- **Git**: 最新版本
- **IDE**: VS Code 或 Android Studio

### 平台要求

#### macOS 开发环境
- **系统版本**: macOS 10.14+
- **Xcode**: 12.0+ (iOS开发)
- **CocoaPods**: 最新版本

#### Windows 开发环境
- **系统版本**: Windows 10+
- **Android SDK**: 最新版本
- **PowerShell**: 5.0+

#### Linux 开发环境
- **发行版**: Ubuntu 18.04+ 或其他主流发行版
- **工具**: curl, git, unzip, xz-utils

## 🚀 快速开始

### 1. 克隆项目

```bash
# 克隆代码库
git clone https://github.com/your-repo/powergo-app.git
cd powergo-app

# 查看项目结构
ls -la
```

### 2. 安装Flutter依赖

```bash
# 获取依赖包
flutter pub get

# 验证安装
flutter doctor
```

如果 `flutter doctor` 显示问题，请根据提示解决。

### 3. 运行开发版本

#### Web 开发 (推荐开始方式)
```bash
# 启动Web开发服务器
flutter run -d chrome

# 或者指定端口
flutter run -d chrome --web-port=8080
```

#### Android 开发
```bash
# 连接Android设备或启动模拟器
flutter devices

# 运行到Android设备
flutter run -d android
```

#### macOS 桌面开发
```bash
# 启用macOS桌面支持
flutter config --enable-macos-desktop

# 运行macOS应用
flutter run -d macos
```

## 🔧 详细环境配置

### Flutter SDK 安装

#### macOS/Linux
```bash
# 下载Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable

# 添加到PATH (添加到 ~/.bashrc 或 ~/.zshrc)
export PATH="$PATH:`pwd`/flutter/bin"

# 重载配置
source ~/.bashrc  # 或 source ~/.zshrc

# 验证安装
flutter --version
```

#### Windows
1. 下载Flutter SDK：https://flutter.dev/docs/get-started/install/windows
2. 解压到 `C:\flutter`
3. 添加 `C:\flutter\bin` 到系统PATH
4. 重启命令提示符并验证：`flutter --version`

### Android 开发配置

#### 安装Android Studio
1. 下载并安装 [Android Studio](https://developer.android.com/studio)
2. 安装Android SDK (API Level 21+)
3. 创建Android虚拟设备 (AVD)

#### 设置Android SDK路径
```bash
# 设置环境变量 (添加到 ~/.bashrc 或 ~/.zshrc)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Windows 示例
# set ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk
# set PATH=%PATH%;%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools
```

### iOS 开发配置 (仅 macOS)

PowerGo 已完成完整的iOS配置，支持在iOS设备和模拟器上运行。

#### 系统要求
- **macOS**: 10.14+ 
- **Xcode**: 12.0+
- **iOS**: 13.0+ (最低支持版本)
- **CocoaPods**: 最新版本

#### 安装Xcode
```bash
# 从App Store安装Xcode
# 或下载：https://developer.apple.com/xcode/

# 安装Xcode命令行工具
sudo xcode-select --install

# 接受许可协议
sudo xcodebuild -license accept

# 验证安装
xcodebuild -version
```

#### 安装CocoaPods
```bash
# 安装CocoaPods
sudo gem install cocoapods

# 验证安装
pod --version

# 初始化CocoaPods (首次使用)
pod setup
```

#### 启用Flutter iOS支持
```bash
# 启用iOS平台支持
flutter config --enable-ios

# 验证iOS支持
flutter doctor -v
# 应该显示iOS工具链已安装
```

#### iOS项目初始化
```bash
# 安装iOS依赖
cd ios
pod install
cd ..

# 验证iOS项目配置
flutter build ios --no-codesign --debug
```

#### iOS应用配置详情

**已配置的功能**：
- ✅ 网络权限 (SSH连接、WOL功能)
- ✅ 本地网络访问权限  
- ✅ 应用图标 (所有尺寸，App Store兼容)
- ✅ 最低系统版本 iOS 13.0
- ✅ CocoaPods依赖管理

**Info.plist 权限配置**：
```xml
<!-- 网络权限配置 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- 本地网络使用说明 -->
<key>NSLocalNetworkUsageDescription</key>
<string>PowerGo needs access to local network to manage servers and perform Wake-on-LAN operations.</string>
```

#### iOS开发和测试
```bash
# 在iOS模拟器中运行
flutter run -d ios

# 查看可用的iOS设备/模拟器
flutter devices

# 运行到特定设备
flutter run -d <device-id>

# 构建调试版本
flutter build ios --debug

# 构建发布版本
flutter build ios --release
```

#### Xcode项目操作
```bash
# 在Xcode中打开项目
open ios/Runner.xcworkspace

# 注意: 务必使用 .xcworkspace 文件，不是 .xcodeproj
```

#### iOS功能支持状态

**完全支持**：
- ✅ SSH远程连接 (dartssh2库)
- ✅ 服务器状态检测
- ✅ 本地数据存储 (SharedPreferences)
- ✅ 应用设置管理
- ✅ 深色/浅色主题切换
- ✅ 中文界面

**iOS特殊实现**：
- ⚠️ **Wake-on-LAN**: 通过UDP Socket发送魔术包
- ⚠️ **MAC地址探测**: 通过SSH远程查询 (iOS沙盒限制)
- ⚠️ **网络扫描**: 通过HTTP/TCP连接检测

#### iOS发布准备

**代码签名配置**：
1. 在Xcode中打开 `ios/Runner.xcworkspace`
2. 选择Runner target → Signing & Capabilities
3. 配置Team和Bundle Identifier
4. 选择适当的Provisioning Profile

**App Store发布检查**：
- [ ] Bundle Identifier设置为唯一值
- [ ] 版本号和构建号已更新
- [ ] 应用图标无alpha通道 ✅ (已配置)
- [ ] 隐私权限描述完整 ✅ (已配置)
- [ ] 在真机上测试网络功能

#### 常见问题解决

**CocoaPods问题**:
```bash
# 清理并重新安装
cd ios
rm -rf Pods/
rm Podfile.lock  
pod install
cd ..
```

**Xcode构建问题**:
```bash
# 清理Flutter构建缓存
flutter clean
flutter pub get

# 重新安装iOS依赖
cd ios && pod install
```

**代码签名问题**:
- 确保在Xcode中配置了有效的开发团队
- 检查Bundle Identifier是否与证书匹配
- 验证Provisioning Profile是否有效

### macOS 桌面开发配置

```bash
# 启用macOS桌面支持
flutter config --enable-macos-desktop

# 验证支持
flutter devices
# 应该显示 "macOS" 作为可用设备
```

## 🎯 项目特定配置

### 1. 图标生成配置

项目使用 `flutter_launcher_icons` 生成应用图标：

```bash
# 生成图标 (已配置)
dart run flutter_launcher_icons

# 如果需要修改图标，编辑 pubspec.yaml 中的配置：
# flutter_launcher_icons:
#   android: "ic_launcher"
#   image_path: "assets/images/powergo_icon.png"
```

### 2. 开发脚本

项目提供了便捷的开发脚本：

```bash
# 使用开发脚本 (如果存在)
chmod +x dev.sh
./dev.sh

# 或者手动运行Web开发
flutter run -d chrome --hot
```

### 3. 依赖说明

主要依赖及其用途：

```yaml
dependencies:
  shared_preferences: ^2.2.2     # 本地数据存储
  http: ^1.1.0                   # HTTP网络请求  
  dartssh2: ^2.9.0              # SSH连接 (原生环境)
  package_info_plus: ^8.0.2     # 应用版本信息
  flutter_launcher_icons: ^0.13.1 # 图标生成

dev_dependencies:
  flutter_test: sdk              # 单元测试框架
  flutter_lints: ^2.0.0         # 代码规范检查
```

## 🏗️ 构建和部署

### 开发构建

```bash
# Debug版本 (快速迭代)
flutter run --debug

# Profile版本 (性能测试)
flutter run --profile

# Release版本 (性能优化)
flutter run --release
```

### 生产构建

#### Android APK
```bash
# 构建Release APK
flutter build apk --release

# 构建AAB (Google Play)
flutter build appbundle --release

# 输出位置
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

#### iOS App (仅 macOS)

PowerGo已完成iOS平台配置，支持完整的iOS开发和发布流程。

**开发构建**:
```bash
# 在iOS模拟器中运行
flutter run -d ios

# 构建调试版本
flutter build ios --debug

# 构建无签名版本 (测试用)
flutter build ios --no-codesign --debug
```

**发布构建**:
```bash
# 构建发布版本 (需要有效签名)
flutter build ios --release

# 构建企业版或测试版
flutter build ios --release --flavor development
```

**Xcode操作**:
```bash
# 在Xcode中打开项目 (必须使用workspace)
open ios/Runner.xcworkspace

# Archive构建 (用于App Store提交)
# 在Xcode中: Product → Archive
```

**iOS构建输出位置**:
- Debug: `build/ios/Debug-iphoneos/Runner.app`
- Release: `build/ios/Release-iphoneos/Runner.app`
- Archive: 在Xcode Organizer中管理

**App Store发布流程**:
1. 在Xcode中Archive应用
2. 在Organizer中验证Archive
3. 上传到App Store Connect
4. 在App Store Connect中配置应用信息
5. 提交审核

#### macOS 应用
```bash
# 构建macOS应用
flutter build macos --release

# 输出位置: build/macos/Build/Products/Release/PowerGo.app
```

#### Web 应用
```bash
# 构建Web应用
flutter build web --release

# 输出位置: build/web/
# 可以部署到任何Web服务器
```

## 🧪 测试

### 运行测试
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart

# 生成覆盖率报告
flutter test --coverage
```

### 代码质量检查
```bash
# 运行代码分析
flutter analyze

# 格式化代码
flutter format lib/

# 检查依赖
flutter pub deps
```

## 🔍 调试技巧

### VS Code 调试配置

创建 `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "PowerGo (Chrome)",
            "request": "launch",
            "type": "dart",
            "deviceId": "chrome",
            "program": "lib/main.dart"
        },
        {
            "name": "PowerGo (Android)",
            "request": "launch",
            "type": "dart",
            "deviceId": "android",
            "program": "lib/main.dart"
        }
    ]
}
```

### 调试工具
```bash
# Flutter Inspector (调试UI)
flutter run --debug
# 然后在IDE中打开Flutter Inspector

# 性能分析
flutter run --profile
# 使用DevTools进行性能分析

# 日志查看
flutter logs
```

## 📱 设备测试

### Android 设备
```bash
# 列出连接的设备
adb devices

# 安装到指定设备
flutter install -d <device-id>

# 查看日志
flutter logs -d android
```

### iOS 设备 (仅 macOS)
```bash
# 列出iOS设备
instruments -s devices

# 运行到iOS设备
flutter run -d ios

# 查看日志
flutter logs -d ios
```

## 🐛 常见问题解决

### 1. Flutter Doctor 问题

```bash
# Android许可问题
flutter doctor --android-licenses

# iOS部署问题 (macOS)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# 路径问题
echo $PATH
# 确保Flutter和Android SDK在PATH中
```

### 2. 依赖冲突
```bash
# 清理依赖
flutter clean
flutter pub get

# 升级依赖
flutter pub upgrade

# 检查过时的包
flutter pub outdated
```

### 3. 平台特定问题

#### Android
```bash
# Gradle构建失败
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### iOS (macOS)
```bash
# CocoaPods问题
cd ios
rm Podfile.lock
rm -rf Pods/
pod install
cd ..
```

#### macOS桌面
```bash
# 权限问题
cd macos
rm -rf Pods/
pod install
cd ..
```

## 🔧 开发工具推荐

### IDE扩展
#### VS Code
- **Flutter**: 官方Flutter扩展
- **Dart**: Dart语言支持
- **Flutter Widget Snippets**: 代码片段
- **Awesome Flutter Snippets**: 额外代码片段

#### Android Studio
- **Flutter Plugin**: 官方Flutter插件
- **Dart Plugin**: Dart语言支持

### 命令行工具
```bash
# 性能监控
flutter pub global activate devtools
dart devtools

# 代码生成
flutter pub global activate build_runner

# 国际化
flutter pub global activate intl_utils
```

## 📚 学习资源

### 官方文档
- [Flutter官方文档](https://flutter.dev/docs)
- [Dart语言指南](https://dart.dev/guides)
- [Material Design](https://material.io/design)

### 社区资源
- [Flutter中文网](https://flutterchina.club/)
- [Flutter包管理](https://pub.dev/)
- [Flutter示例](https://flutter.github.io/samples/)

## 🤝 贡献流程

### 1. 设置开发环境
按照本文档完成环境配置

### 2. 创建功能分支
```bash
git checkout -b feature/your-feature-name
```

### 3. 开发和测试
```bash
# 开发功能
# 运行测试
flutter test

# 代码检查
flutter analyze
```

### 4. 提交代码
```bash
git add .
git commit -m "feat: add your feature description"
git push origin feature/your-feature-name
```

### 5. 创建Pull Request
在GitHub上创建PR，描述您的更改

## 🆘 获取帮助

如果遇到问题：

1. 查看 [Flutter官方文档](https://flutter.dev/docs)
2. 搜索 [GitHub Issues](https://github.com/your-repo/powergo/issues)
3. 在项目中创建新的Issue
4. 加入Flutter开发者社区讨论

---

**快乐编码！** 🚀 让我们一起让PowerGo变得更加强大！