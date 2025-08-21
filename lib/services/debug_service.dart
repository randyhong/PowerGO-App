import 'package:shared_preferences/shared_preferences.dart';

/// 调试日志服务 - 用于收集和管理应用调试信息
class DebugService {
  static const String _debugLogsKey = 'debug_logs';
  static const String _debugEnabledKey = 'debug_enabled';
  static const int _maxLogEntries = 1000; // 最多保存1000条日志
  
  static bool _isEnabled = false;
  static List<String> _logs = [];
  
  /// 初始化调试服务
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_debugEnabledKey) ?? false;
    
    // 加载已保存的日志
    final savedLogs = prefs.getStringList(_debugLogsKey) ?? [];
    _logs = List.from(savedLogs);
  }
  
  /// 添加调试日志
  static Future<void> log(String message, {String? category}) async {
    if (!_isEnabled) return;
    
    final timestamp = DateTime.now().toString().substring(5, 19); // MM-dd HH:mm:ss
    final categoryPrefix = category != null ? '[$category] ' : '';
    final logEntry = '[$timestamp] $categoryPrefix$message';
    
    _logs.add(logEntry);
    
    // 限制日志数量，删除最旧的日志
    if (_logs.length > _maxLogEntries) {
      _logs.removeAt(0);
    }
    
    // 异步保存到本地存储
    _saveLogs();
  }
  
  /// 获取所有日志
  static List<String> getAllLogs() {
    return List.from(_logs);
  }
  
  /// 获取最新的N条日志
  static List<String> getRecentLogs(int count) {
    if (_logs.length <= count) return List.from(_logs);
    return _logs.sublist(_logs.length - count);
  }
  
  /// 清空所有日志
  static Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();
  }
  
  /// 启用/禁用调试日志
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugEnabledKey, enabled);
    
    if (enabled) {
      await log('🚀 调试日志已启用', category: 'SYSTEM');
    }
  }
  
  /// 检查调试是否启用
  static bool isEnabled() => _isEnabled;
  
  /// 获取日志统计信息
  static Map<String, dynamic> getLogStats() {
    return {
      'totalLogs': _logs.length,
      'isEnabled': _isEnabled,
      'maxEntries': _maxLogEntries,
      'firstLogTime': _logs.isNotEmpty ? _logs.first.substring(1, 18) : null,
      'lastLogTime': _logs.isNotEmpty ? _logs.last.substring(1, 18) : null,
    };
  }
  
  /// 导出日志为文本
  static String exportLogs() {
    final header = '''
PowerGo 调试日志导出
导出时间: ${DateTime.now().toString()}
总日志数: ${_logs.length}
调试状态: ${_isEnabled ? "启用" : "禁用"}

=====================================

''';
    
    return header + _logs.join('\n');
  }
  
  /// 保存日志到本地存储
  static Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_debugLogsKey, _logs);
    } catch (e) {
      print('保存调试日志失败: $e');
    }
  }
  
  /// 快捷方法 - MAC检测日志
  static Future<void> logMacDetection(String message) async {
    await log(message, category: 'MAC');
  }
  
  /// 快捷方法 - 服务器操作日志
  static Future<void> logServerAction(String message) async {
    await log(message, category: 'SERVER');
  }
  
  /// 快捷方法 - 网络操作日志
  static Future<void> logNetwork(String message) async {
    await log(message, category: 'NETWORK');
  }
  
  /// 快捷方法 - 错误日志
  static Future<void> logError(String message, [dynamic error]) async {
    final errorMsg = error != null ? '$message: $error' : message;
    await log('❌ $errorMsg', category: 'ERROR');
  }
}