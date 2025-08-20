import 'dart:async'; // Import Timer

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/server.dart';
import '../services/storage_service.dart';
import '../services/server_service.dart';
import '../services/settings_service.dart';
import '../widgets/server_card.dart';
import './add_server_screen.dart'; // Import AddServerScreen

class ServersScreen extends StatefulWidget {
  const ServersScreen({Key? key}) : super(key: key);

  @override
  State<ServersScreen> createState() => ServersScreenState();
}

class ServersScreenState extends State<ServersScreen> with WidgetsBindingObserver {
  List<Server> servers = [];
  bool isLoading = false;

  bool _isAutoRefreshEnabled = true; // Default to true
  Timer? _autoRefreshTimer;
  int _autoRefreshInterval = 3; // 默认3秒

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings(); // 加载设置
    _loadServers(); // Initial load
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final autoRefresh = await SettingsService.getAutoRefresh();
    final interval = await SettingsService.getRefreshInterval();
    
    setState(() {
      _isAutoRefreshEnabled = autoRefresh;
      _autoRefreshInterval = interval;
    });
    
    if (_isAutoRefreshEnabled) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefresh();
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

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel(); // Cancel any existing timer
    if (_isAutoRefreshEnabled && mounted) {
      _autoRefreshTimer = Timer.periodic(Duration(seconds: _autoRefreshInterval), (timer) {
        if (!isLoading && mounted) { // Check isLoading and mounted
          _loadServers();
        }
      });
    }
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _loadServers() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final loadedServers = await StorageService.getServers();
      if (!mounted) return;
      setState(() {
        servers = loadedServers;
      });
      await _checkAllServersStatus(); // await to ensure status is checked before isLoading is false
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('加载服务器失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 公共刷新方法，供外部调用
  void refreshServers() {
    _loadServers();
  }

  // 响应设置变化的方法，供外部调用
  void onSettingsChanged() {
    _loadSettings(); // 重新加载设置并更新UI状态
  }

  Future<void> _checkAllServersStatus() async {
    print('开始检查所有服务器状态...');
    bool anyStatusChanged = false;
    for (int i = 0; i < servers.length; i++) {
      final server = servers[i];
      try {
        print('正在检查服务器: ${server.name} (${server.host}:${server.port})');
        final status = await ServerService.checkServerStatus(server);
        print('服务器 ${server.name} 状态: ${status.isOnline ? "在线" : "离线"} ${status.pingTime != null ? "(${status.pingTime}ms)" : ""}');

        if (!mounted) return;
        
        if (servers[i].isOnline != status.isOnline || servers[i].pingTime != status.pingTime) {
           anyStatusChanged = true;
           servers[i] = server.copyWith(
            isOnline: status.isOnline,
            pingTime: status.pingTime,
          );
          // Persist status change - this was in original code
           await StorageService.updateServer(servers[i]);
        }
      } catch (e) {
        print('检查服务器状态失败: ${server.name} - $e');
        if (!mounted) return;
         if (servers[i].isOnline != false || servers[i].pingTime != null) {
            anyStatusChanged = true;
            servers[i] = server.copyWith(
              isOnline: false,
              pingTime: null,
            );
         }
      }
    }
    if (anyStatusChanged && mounted) {
      setState(() {}); // Update UI only if any status actually changed
    }
    print('所有服务器状态检查完成');
  }

  Future<void> _deleteServer(Server server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除服务器 "${server.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StorageService.deleteServer(server.id);
        await _loadServers(); // Refresh list after delete
        _showSuccessSnackBar('服务器删除成功');
      } catch (e) {
        _showErrorSnackBar('删除服务器失败: $e');
      }
    }
  }

  Future<void> _navigateToEditServerScreen(Server server) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServerScreen(server: server),
      ),
    );

    if (result == true && mounted) {
      _loadServers(); 
      _showSuccessSnackBar('服务器更新成功');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PowerGo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '手动刷新',
            onPressed: isLoading ? null : _loadServers, // Disable if already loading
          ),
          Tooltip(
            message: _isAutoRefreshEnabled ? '关闭自动刷新' : '开启自动刷新 (每3秒)',
            child: Transform.scale(
              scale: 0.8, // 缩放到80%大小
              child: Switch(
                value: _isAutoRefreshEnabled,
                onChanged: (bool value) async {
                  if (!mounted) return;
                  
                  // 保存设置到存储
                  await SettingsService.setAutoRefresh(value);
                  
                  setState(() {
                    _isAutoRefreshEnabled = value;
                  });
                  if (_isAutoRefreshEnabled) {
                    _startAutoRefresh();
                  } else {
                    _stopAutoRefresh();
                  }
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 减少点击区域
              ),
            ),
          ),
          const SizedBox(width: 8), // Padding from the edge
        ],
      ),
      body: isLoading && servers.isEmpty // Show loading only if servers list is empty initially
          ? const Center(child: CircularProgressIndicator())
          : servers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.dns_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '暂无服务器',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '点击下方添加按钮添加服务器',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadServers, // Manual pull-to-refresh
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: servers.length + (kIsWeb ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (kIsWeb && index == 0) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.orange.shade50,
                          child: Padding( // Removed const
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Web环境限制提示',
                                        style: TextStyle( // Not const
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '在Web浏览器中无法准确检测内网服务器状态。建议使用原生应用(macOS/Android)获得完整功能。',
                                        style: TextStyle( // Not const
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final serverIndex = kIsWeb ? index - 1 : index;
                      if (serverIndex < 0 || serverIndex >= servers.length) {
                        // Should not happen if itemCount is correct
                        return const SizedBox.shrink(); 
                      }
                      final server = servers[serverIndex];
                      
                      return ServerCard(
                        server: server,
                        onDelete: () => _deleteServer(server),
                        onEdit: () => _navigateToEditServerScreen(server),
                        onRefresh: _loadServers, 
                      );
                    },
                  ),
                ),
    );
  }
}
