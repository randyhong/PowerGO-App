import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/server.dart';
import '../services/server_service.dart';

class ServerCard extends StatefulWidget {
  final Server server;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  const ServerCard({
    Key? key,
    required this.server,
    required this.onDelete,
    required this.onEdit,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard> {
  bool isExecutingAction = false;

  Future<void> _executePowerAction(PowerAction action) async {
    // 为关机和重启操作显示确认对话框
    if (action == PowerAction.shutdown || action == PowerAction.restart) {
      final confirmed = await _showPowerActionConfirmDialog(action);
      if (!confirmed) {
        return; // 用户取消了操作
      }
    }

    setState(() {
      isExecutingAction = true;
    });

    try {
      // WOL操作前检查MAC地址
      if (action == PowerAction.wakeup) {
        if (!widget.server.supportsWOL) {
          _showErrorSnackBar('开机失败：未配置MAC地址\n请编辑服务器信息添加MAC地址以启用WOL功能');
          return;
        }
        
        // 检查WOL支持 (这可能是一个额外的检查，例如网络环境)
        // final supportResult = await WakeOnLanService.checkWOLSupport(widget.server);
        // if (!supportResult.isSupported) {
        //   _showErrorSnackBar('WOL不支持：${supportResult.reason}\n${supportResult.details}');
        //   return;
        // }
        
        // if (supportResult.webLimited) {
        //   _showWarningSnackBar('Web环境限制：${supportResult.details}');
        // }
      }

      final success = await ServerService.executePowerAction(widget.server, action);
      if (success) {
        String actionName;
        String successMessage;
        switch (action) {
          case PowerAction.shutdown:
            actionName = '关机';
            successMessage = '$actionName 指令发送成功\n使用sudo权限执行，支持密码认证';
            break;
          case PowerAction.restart:
            actionName = '重启';
            successMessage = '$actionName 指令发送成功\n使用sudo权限执行，支持密码认证';
            break;
          case PowerAction.wakeup:
            actionName = '开机';
            successMessage = 'WOL魔术包发送成功\n目标MAC: ${widget.server.formattedMacAddress}\n请等待服务器启动...';
            break;
        }
        _showSuccessSnackBar(successMessage);
        
        // 延迟后刷新状态（WOL需要更长时间）
        final delaySeconds = action == PowerAction.wakeup ? 10 : 3;
        Future.delayed(Duration(seconds: delaySeconds), () {
          widget.onRefresh();
        });
      } else {
        String errorMessage;
        switch (action) {
          case PowerAction.wakeup:
            errorMessage = 'WOL唤醒失败\n请检查MAC地址和网络配置';
            break;
          default:
            errorMessage = '操作失败，请检查服务器连接';
        }
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      _showErrorSnackBar('操作失败: $e');
    } finally {
      setState(() {
        isExecutingAction = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _showPowerActionConfirmDialog(PowerAction action) async {
    String actionName;
    String actionDesc;
    Color actionColor;
    IconData actionIcon;

    switch (action) {
      case PowerAction.shutdown:
        actionName = '关机';
        actionDesc = '将关闭服务器系统，服务器将停止运行';
        actionColor = Colors.red;
        actionIcon = Icons.power_settings_new;
        break;
      case PowerAction.restart:
        actionName = '重启';
        actionDesc = '将重新启动服务器系统';
        actionColor = Colors.orange;
        actionIcon = Icons.refresh;
        break;
      default:
        return true; // 其他操作不需要确认
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(actionIcon, color: actionColor),
            const SizedBox(width: 8),
            Text('确认$actionName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('服务器: ${widget.server.name}'),
            Text('地址: ${widget.server.host}:${widget.server.port}'),
            const SizedBox(height: 12),
            Text(actionDesc),
            const SizedBox(height: 8),
            Text(
              '确定要执行此操作吗？',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: actionColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            child: Text('确认$actionName'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.server.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.server.host}:${widget.server.port}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        widget.onEdit();
                        break;
                      case 'delete':
                        widget.onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.server.isOnline ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.server.isOnline ? '在线' : '离线',
                  style: TextStyle(
                    color: widget.server.isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.server.isOnline && widget.server.pingTime != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Ping: ${widget.server.pingTime}ms',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                // Web环境提示
                if (kIsWeb && !widget.server.isOnline) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Web环境无法检测内网服务器状态，请使用原生应用获得准确结果',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
                ],
                
                // WOL状态提示 - MODIFIED
                const SizedBox(width: 8),
                Tooltip(
                  message: widget.server.supportsWOL 
                           ? 'WOL支持 - MAC: ${widget.server.formattedMacAddress}' 
                           : 'WOL不支持 (未配置MAC地址)',
                  child: Icon(
                    Icons.power, // You could use a different icon like Icons.power_off for unsupported state
                    size: 16,
                    color: widget.server.supportsWOL ? Colors.blue : Colors.grey, // Dynamic color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.server.isOnline) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isExecutingAction
                          ? null
                          : () => _executePowerAction(PowerAction.shutdown),
                      icon: isExecutingAction
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.power_settings_new),
                      label: const Text('关机'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isExecutingAction
                          ? null
                          : () => _executePowerAction(PowerAction.restart),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重启'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isExecutingAction
                          ? null
                          : () => _executePowerAction(PowerAction.wakeup),
                      icon: isExecutingAction
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('开机'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        // Disable button if WOL is not supported
                        disabledBackgroundColor: !widget.server.supportsWOL ? Colors.grey[300] : null,
                        disabledForegroundColor: !widget.server.supportsWOL ? Colors.grey[500] : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}