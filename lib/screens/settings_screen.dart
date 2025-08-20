import 'package:flutter/material.dart';
import 'package:powergo/services/storage_service.dart';
import 'package:powergo/services/settings_service.dart';
import 'package:powergo/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  
  const SettingsScreen({Key? key, this.onSettingsChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _autoRefresh = true;
  int _refreshInterval = 30;
  String _appVersion = '加载中...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadPackageInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用恢复前台时，重新加载设置以确保同步
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final themeMode = await SettingsService.getThemeMode();
    final autoRefresh = await SettingsService.getAutoRefresh();
    final refreshInterval = await SettingsService.getRefreshInterval();
    
    setState(() {
      _themeMode = themeMode;
      _autoRefresh = autoRefresh;
      _refreshInterval = refreshInterval;
    });
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return '自动跟随系统设置';
      case AppThemeMode.light:
        return '始终使用浅色主题';
      case AppThemeMode.dark:
        return '始终使用深色主题';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.palette),
                  title: Text(
                    '外观设置',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: const Text('主题模式'),
                  subtitle: Text(_getThemeModeDescription(_themeMode)),
                  trailing: DropdownButton<AppThemeMode>(
                    value: _themeMode,
                    items: const [
                      DropdownMenuItem(
                        value: AppThemeMode.system,
                        child: Text('跟随系统'),
                      ),
                      DropdownMenuItem(
                        value: AppThemeMode.light,
                        child: Text('浅色模式'),
                      ),
                      DropdownMenuItem(
                        value: AppThemeMode.dark,
                        child: Text('深色模式'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await SettingsService.setThemeMode(value);
                        setState(() {
                          _themeMode = value;
                        });
                        // 更新应用主题
                        if (mounted) {
                          PowerGoApp.updateTheme(context);
                        }
                        // 通知其他页面设置已更改
                        widget.onSettingsChanged?.call();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text(
                    '自动刷新',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('启用自动刷新'),
                  subtitle: const Text('自动检查服务器状态'),
                  value: _autoRefresh,
                  onChanged: (value) async {
                    await SettingsService.setAutoRefresh(value);
                    setState(() {
                      _autoRefresh = value;
                    });
                    // 通知其他页面设置已更改
                    widget.onSettingsChanged?.call();
                  },
                ),
                if (_autoRefresh)
                  ListTile(
                    title: const Text('刷新间隔'),
                    subtitle: Text('$_refreshInterval 秒'),
                    trailing: DropdownButton<int>(
                      value: _refreshInterval,
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3秒')),
                        DropdownMenuItem(value: 5, child: Text('5秒')),
                        DropdownMenuItem(value: 10, child: Text('10秒')),
                        DropdownMenuItem(value: 30, child: Text('30秒')),
                        DropdownMenuItem(value: 60, child: Text('1分钟')),
                      ],
                      onChanged: (value) async {
                        await SettingsService.setRefreshInterval(value!);
                        setState(() {
                          _refreshInterval = value;
                        });
                        // 通知其他页面设置已更改
                        widget.onSettingsChanged?.call();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    '关于',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: const Text('应用版本'),
                  subtitle: Text('$_appVersion${_buildNumber.isNotEmpty ? ' (Build $_buildNumber)' : ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                ListTile(
                  title: const Text('清除所有数据'),
                  subtitle: const Text('删除所有服务器配置'),
                  trailing: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: () {
                    _showClearDataDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'PowerGo',
      applicationVersion: '$_appVersion${_buildNumber.isNotEmpty ? ' (Build $_buildNumber)' : ''}',
      applicationIcon: const Icon(Icons.power_settings_new, size: 64),
      children: const [
        Text('PowerGo 是一款跨平台的服务器远程管理应用，支持基础的电源控制操作。'),
      ],
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('此操作将删除所有服务器配置，且无法恢复。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.saveServers([]);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('所有数据已清除'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}