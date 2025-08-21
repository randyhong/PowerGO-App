import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:powergo/services/storage_service.dart';
import 'package:powergo/services/settings_service.dart';
import 'package:powergo/services/debug_service.dart';
import 'package:powergo/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  
  const SettingsScreen({Key? key, this.onSettingsChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _autoRefresh = true;
  int _refreshInterval = 30;
  String _appVersion = '加载中...';
  String _buildNumber = '';
  bool _debugEnabled = false;

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
    final debugEnabled = DebugService.isEnabled();
    
    setState(() {
      _themeMode = themeMode;
      _autoRefresh = autoRefresh;
      _refreshInterval = refreshInterval;
      _debugEnabled = debugEnabled;
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

  // 响应外部设置变化的方法，供主屏幕调用
  void onSettingsChanged() {
    _loadSettings(); // 重新加载设置并更新UI状态
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
                  leading: Icon(Icons.bug_report),
                  title: Text(
                    '调试功能',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('启用调试日志'),
                  subtitle: const Text('记录应用运行日志，用于问题排查'),
                  value: _debugEnabled,
                  onChanged: (value) async {
                    await DebugService.setEnabled(value);
                    setState(() {
                      _debugEnabled = value;
                    });
                    widget.onSettingsChanged?.call();
                  },
                ),
                if (_debugEnabled) ...[
                  ListTile(
                    title: const Text('查看调试日志'),
                    subtitle: const Text('查看详细的应用运行日志'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDebugLogs(),
                  ),
                  ListTile(
                    title: const Text('清空调试日志'),
                    subtitle: const Text('删除所有已记录的调试信息'),
                    trailing: const Icon(Icons.delete, color: Colors.orange),
                    onTap: () => _clearDebugLogs(),
                  ),
                ],
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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

  void _showDebugLogs() {
    final logs = DebugService.getAllLogs();
    final stats = DebugService.getLogStats();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('调试日志'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _exportLogs(),
              ),
            ],
          ),
          body: Column(
            children: [
              // 统计信息
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日志统计',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('总日志数: ${stats['totalLogs']}'),
                    if (stats['firstLogTime'] != null)
                      Text('最早日志: ${stats['firstLogTime']}'),
                    if (stats['lastLogTime'] != null)
                      Text('最新日志: ${stats['lastLogTime']}'),
                  ],
                ),
              ),
              // 日志列表
              Expanded(
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无调试日志\n\n执行一些操作（如添加服务器）后\n日志将在这里显示',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // 日志内容区域
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  child: Text(
                                    logs.join('\n'), // 正序显示，所有日志连接成一个文本
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      height: 1.3,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 底部操作栏
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border(
                                  top: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Icon(Icons.info_outline, 
                                    size: 16, 
                                    color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    '共 ${logs.length} 条日志',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _copyLogsToClipboard(logs),
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('复制'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空调试日志'),
        content: const Text('确定要删除所有调试日志吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await DebugService.clearLogs();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('调试日志已清空'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('确定', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    final exportContent = DebugService.exportLogs();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出调试日志'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('日志已准备好导出'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  exportContent,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _copyLogsToClipboard(List<String> logs) async {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有日志可复制'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final logContent = logs.join('\n');
    await Clipboard.setData(ClipboardData(text: logContent));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制 ${logs.length} 条日志到剪贴板'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: '查看',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('已复制的内容'),
                content: Container(
                  width: double.maxFinite,
                  height: 300,
                  child: SingleChildScrollView(
                    child: Text(
                      logContent,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}