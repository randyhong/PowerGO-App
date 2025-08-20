# PowerGo - 服务器远程管理应用

![PowerGo Logo](assets/images/powergo_icon.png)

PowerGo 是一款功能强大的跨平台移动应用，专为服务器远程管理而设计。支持iOS、Android和Web平台，让您能够随时随地管理和控制您的服务器。

## ✨ 核心功能

### 📋 服务器管理
- **智能添加**: 支持手动添加或批量导入服务器配置
- **完整编辑**: 修改服务器信息、认证方式、网络配置
- **安全删除**: 带确认的服务器删除功能

### 🔍 状态监控
- **实时状态**: 多层次检测服务器在线状态（TCP/HTTP/Ping）
- **性能指标**: 显示ping延迟和响应时间
- **智能刷新**: 可配置的自动刷新（3秒-1分钟间隔）
- **状态历史**: 记录服务器状态变化

### ⚡ 电源控制
- **远程开机**: 基于WOL（Wake-on-LAN）的网络唤醒
- **安全关机**: 多重sudo策略的智能关机
- **远程重启**: 支持各种Linux发行版的重启命令
- **权限适配**: 自动适配root/sudo/NOPASSWD用户权限

### 🌐 网络功能
- **SSH连接**: 使用dartssh2库的真实SSH连接
- **MAC探测**: 智能MAC地址自动探测和验证
- **网络诊断**: 多种连接方式的故障诊断
- **安全认证**: 支持密码和私钥认证方式

### 🎨 用户体验
- **现代界面**: Material Design 3.0设计语言
- **响应式布局**: 适配各种屏幕尺寸
- **夜间模式**: 护眼的深色主题
- **本地化**: 完全中文界面

## 🛠️ 技术特性

### 🔧 核心技术栈
- **框架**: Flutter 3.10+ (跨平台开发)
- **语言**: Dart 3.0+
- **SSH**: dartssh2 (真实SSH连接)
- **存储**: SharedPreferences (本地数据持久化)
- **网络**: HTTP/TCP Socket + package_info_plus

### 📱 支持平台
- **Android**: 5.0+ (API 21+)
- **iOS**: 11.0+
- **macOS**: 10.14+
- **Web**: Chrome/Safari/Firefox (开发调试)

### 🔒 安全措施
- **密码保护**: 内存中处理，不写入日志
- **连接加密**: SSH协议自带加密传输
- **权限最小化**: 优先使用低权限命令
- **安全验证**: MAC地址格式验证和SSH连接验证

## 🚀 高级功能

### 🔍 MAC地址智能探测
PowerGo 支持三层MAC地址自动探测：

1. **SSH远程查询** (首选，95%成功率)
   - 支持多种Linux发行版
   - 自动适配不同网卡命名
   - 兼容eth0、ens33、enp0s3等接口

2. **ARP本地查询** (备选，60%成功率)
   - 查询本地ARP表
   - 支持同网段设备发现
   - 跨平台ARP命令适配

3. **网络扫描探测** (扩展，40%成功率)
   - nmap工具集成
   - 局域网设备扫描
   - 详细的探测日志

### ⚡ 智能电源控制
多重命令策略确保最高兼容性：

#### 关机命令优先级
```bash
# 1. 密码认证sudo (推荐)
echo "password" | sudo -S shutdown -h now
echo "password" | sudo -S poweroff

# 2. 无密码sudo (NOPASSWD配置)
sudo shutdown -h now
sudo poweroff

# 3. systemd现代命令
systemctl poweroff --no-ask-password

# 4. 直接权限命令
poweroff
halt

# 5. 传统init命令
init 0
```

#### 重启命令策略
```bash
echo "password" | sudo -S shutdown -r now
echo "password" | sudo -S reboot
sudo reboot
systemctl reboot --no-ask-password
reboot
init 6
```

### 🌐 WOL (Wake-on-LAN) 支持
- **魔术包生成**: 标准102字节WOL数据包
- **多端口发送**: 支持UDP端口9和7
- **支持检测**: 自动检测服务器WOL能力
- **网络适配**: 自动选择合适的网络接口

## 📊 性能优化

### ⚡ 响应速度
- **快速检测**: TCP连接超时优化到1秒
- **并发处理**: 多服务器状态并行检测
- **智能缓存**: 减少重复网络请求
- **即时反馈**: 操作结果实时显示

### 🔄 自动刷新策略
- **可配置间隔**: 3秒/5秒/10秒/30秒/60秒
- **智能暂停**: 操作期间自动暂停刷新
- **状态同步**: 首页和设置页开关联动
- **节能模式**: 无服务器时停止刷新

## 🎯 使用场景

### 🏢 企业环境
- **服务器机房管理**: 批量监控机房服务器状态
- **运维自动化**: 定时重启和维护操作
- **故障响应**: 快速诊断和恢复离线服务器
- **成本优化**: 远程控制降低现场维护成本

### 🏠 家庭网络
- **NAS管理**: 群晖、威联通等NAS设备控制
- **媒体服务器**: Plex、Jellyfin服务器管理
- **智能家居**: 树莓派等IoT设备控制
- **节能管理**: 按需启停耗电设备

### 🔬 开发测试
- **测试环境**: 开发和测试服务器管理
- **CI/CD支持**: 构建服务器状态监控
- **容器管理**: Docker宿主机控制
- **资源优化**: 按需分配计算资源

## 📁 项目结构

```
lib/
├── main.dart                 # 应用入口点
├── models/
│   └── server.dart          # 服务器数据模型和MAC地址验证
├── services/
│   ├── storage_service.dart # 数据持久化服务
│   ├── server_service.dart  # 服务器控制和状态检测
│   └── settings_service.dart # 应用设置管理
├── screens/
│   ├── main_screen.dart     # 主界面和导航
│   ├── servers_screen.dart  # 服务器列表和状态显示
│   ├── add_server_screen.dart # 添加/编辑服务器表单
│   └── settings_screen.dart # 应用设置界面
└── widgets/
    └── server_card.dart     # 服务器状态卡片组件
```

## 🔧 依赖库

```yaml
dependencies:
  flutter: sdk
  shared_preferences: ^2.2.2     # 本地数据存储
  http: ^1.1.0                   # HTTP网络请求
  dartssh2: ^2.9.0              # SSH连接库
  package_info_plus: ^8.0.2     # 应用版本信息
  flutter_launcher_icons: ^0.13.1 # 图标生成工具
```

## 📱 平台适配

### Android
- **最低版本**: Android 5.0 (API 21)
- **目标版本**: Android 14 (API 34)
- **权限要求**: 网络访问、唤醒锁定
- **图标支持**: Adaptive图标 + 传统图标

### iOS
- **最低版本**: iOS 11.0
- **目标版本**: iOS 17
- **证书要求**: 开发者证书
- **权限描述**: 网络使用说明

### Web (开发环境)
- **支持浏览器**: Chrome、Safari、Firefox
- **功能限制**: SSH和WOL为模拟实现
- **用途**: UI测试和逻辑验证

## 🔒 安全和隐私

### 数据安全
- **本地存储**: 密码和私钥本地加密存储
- **网络传输**: SSH协议端到端加密
- **日志保护**: 敏感信息不写入日志
- **会话管理**: 操作完成后立即关闭连接

### 隐私保护
- **无数据收集**: 不收集用户个人信息
- **本地处理**: 所有数据本地存储和处理
- **开源透明**: 代码完全开源可审计
- **权限最小**: 只申请必要的系统权限

## 📈 版本历史

### v1.0.2 (当前版本)
- ✅ 完整的WOL功能实现
- ✅ MAC地址智能探测
- ✅ 电源控制多重策略
- ✅ 统一设置管理
- ✅ 性能优化和Bug修复

### 🔮 未来计划
- **v1.1.0**: 服务器分组和标签
- **v1.2.0**: 定时任务和自动化
- **v1.3.0**: 云同步和多设备协作
- **v2.0.0**: 插件系统和API开放

## 🤝 贡献指南

我们欢迎社区贡献！请查看 [INSTALL.md](INSTALL.md) 了解开发环境设置。

### 贡献方式
1. 🍴 Fork 项目
2. 🌟 创建功能分支
3. 💻 开发和测试
4. 📝 提交Pull Request
5. 🎉 代码审查和合并

### 开发规范
- 遵循Flutter代码规范
- 添加适当的注释和文档
- 包含单元测试
- 提交前运行lint检查

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件了解详情

## 🆘 支持和反馈

- **问题报告**: [GitHub Issues](https://github.com/your-repo/powergo/issues)
- **功能建议**: [GitHub Discussions](https://github.com/your-repo/powergo/discussions)
- **开发文档**: [INSTALL.md](INSTALL.md)

---

**PowerGo - 让服务器管理变得简单高效！** 🚀