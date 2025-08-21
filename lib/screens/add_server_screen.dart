import 'package:flutter/material.dart';
import '../models/server.dart';
import '../services/storage_service.dart';
import '../services/server_service.dart';
import '../services/debug_service.dart';

class AddServerScreen extends StatefulWidget {
  final Server? server;

  const AddServerScreen({Key? key, this.server}) : super(key: key);

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _macAddressController = TextEditingController();

  AuthType _authType = AuthType.password;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isDetectingMac = false;

  @override
  void initState() {
    super.initState();
    if (widget.server != null) {
      _nameController.text = widget.server!.name;
      _hostController.text = widget.server!.host;
      _portController.text = widget.server!.port.toString();
      _usernameController.text = widget.server!.username;
      _passwordController.text = widget.server!.password;
      _macAddressController.text = widget.server!.macAddress ?? '';
      _authType = widget.server!.authType;
    } else {
      _portController.text = '22';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _macAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) return;

    await DebugService.logServerAction('🚀 开始保存服务器: ${_nameController.text.trim()}');
    setState(() {
      _isLoading = true;
    });

    try {
      final macAddress = _macAddressController.text.trim();
      await DebugService.logServerAction('📝 MAC地址输入: "${macAddress.isEmpty ? "空" : macAddress}"');
      
      // 创建服务器对象（不等待MAC地址检测）
      final server = Server(
        id: widget.server?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        authType: _authType,
        macAddress: macAddress.isNotEmpty ? macAddress : null,
      );

      // 立即保存服务器（不等待检测完成）
      if (widget.server != null) {
        await StorageService.updateServer(server);
      } else {
        await StorageService.addServer(server);
      }

      // 异步启动MAC地址检测和状态检测
      await DebugService.logServerAction('💾 服务器保存成功，启动异步检测');
      _performAsyncDetections(server);
      
      // 立即返回上一页面，不等待检测完成
      if (mounted) {
        Navigator.of(context).pop({
          'success': true,
          'switchToServers': true,
        });
      }
    } catch (e) {
      _showErrorSnackBar('保存失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 异步执行MAC地址检测和状态检测（不阻塞用户操作）
  void _performAsyncDetections(Server server) async {
    await DebugService.logServerAction('🔍 开始异步检测 - ${server.name}');
    await DebugService.logServerAction('📡 当前MAC: ${server.macAddress ?? "未设置"}');
    
    // 如果没有MAC地址，异步尝试检测
    if (server.macAddress == null || server.macAddress!.isEmpty) {
      await DebugService.logMacDetection('⚡ 触发MAC检测');
      _performAsyncMacDetection(server);
    } else {
      await DebugService.logMacDetection('⏭️ 跳过MAC检测（已有地址）');
    }
    
    // 异步检测服务器状态
    await DebugService.logNetwork('📊 触发状态检测');
    _performAsyncStatusDetection(server);
  }

  // 异步MAC地址检测
  void _performAsyncMacDetection(Server server) async {
    try {
      await DebugService.logMacDetection('🔍 开始MAC检测: ${server.host}:${server.port}');
      // 使用不修改UI状态的检测方法
      final detectionResult = await MacAddressDetector.detectMacAddress(server);
      
      await DebugService.logMacDetection('🔍 MAC检测完成 - 成功: ${detectionResult.success}');
      if (detectionResult.success && detectionResult.macAddress != null) {
        await DebugService.logMacDetection('✅ 检测到MAC: ${detectionResult.macAddress}');
        // 更新服务器的MAC地址
        final updatedServer = server.copyWith(
          macAddress: detectionResult.macAddress,
        );
        await StorageService.updateServer(updatedServer);
        await DebugService.logMacDetection('💾 MAC已保存: ${server.name}');
      } else {
        await DebugService.logError('MAC检测失败: ${detectionResult.error ?? "未知错误"}');
      }
    } catch (e) {
      await DebugService.logError('MAC检测异常', e);
    }
  }

  // 异步状态检测
  void _performAsyncStatusDetection(Server server) async {
    try {
      print('后台异步检测状态: ${server.name}');
      final status = await ServerService.checkServerStatus(server);
      
      // 更新服务器状态
      final updatedServer = server.copyWith(
        isOnline: status.isOnline,
        pingTime: status.pingTime,
      );
      await StorageService.updateServer(updatedServer);
      print('异步状态检测完成: ${status.isOnline ? "在线" : "离线"}');
    } catch (e) {
      print('异步状态检测出错: $e');
    }
  }

  void _clearForm() {
    _nameController.clear();
    _hostController.clear();
    _portController.text = '22';
    _usernameController.clear();
    _passwordController.clear();
    _macAddressController.clear();
    _authType = AuthType.password;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatMacAddressInput(String input) {
    // 移除所有非十六进制字符
    final cleanInput = input.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    
    // 限制长度为12个字符
    final limitedInput = cleanInput.length > 12 ? cleanInput.substring(0, 12) : cleanInput;
    
    // 格式化为XX:XX:XX:XX:XX:XX格式
    if (limitedInput.isEmpty) return '';
    
    final parts = <String>[];
    for (int i = 0; i < limitedInput.length; i += 2) {
      if (i + 1 < limitedInput.length) {
        parts.add(limitedInput.substring(i, i + 2));
      } else {
        parts.add(limitedInput.substring(i));
      }
    }
    
    return parts.join(':');
  }


  // 手动触发MAC地址探测
  Future<void> _manualDetectMac() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('请先填写完整的服务器连接信息');
      return;
    }

    setState(() {
      _isDetectingMac = true;
    });

    try {
      final tempServer = Server(
        id: 'temp',
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        authType: _authType,
      );

      final result = await MacAddressDetector.detectMacAddress(tempServer);
      
      if (result.success && result.macAddress != null) {
        _macAddressController.text = result.macAddress!;
        _showInfoSnackBar('探测成功: ${result.macAddress}');
      } else {
        _showWarningSnackBar('探测失败\n${result.error ?? "未知错误"}');
      }
    } catch (e) {
      _showErrorSnackBar('探测过程发生错误: $e');
    } finally {
      setState(() {
        _isDetectingMac = false;
      });
    }
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server != null ? '编辑服务器' : '添加服务器'),
        actions: [
          // 测试MAC检测按钮
          IconButton(
            icon: const Icon(Icons.network_check),
            tooltip: '测试MAC检测',
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final server = Server(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text.trim(),
                host: _hostController.text.trim(),
                port: int.parse(_portController.text.trim()),
                username: _usernameController.text.trim(),
                password: _passwordController.text,
                authType: _authType,
                macAddress: null, // 强制为空来触发检测
              );
              await DebugService.logMacDetection('🐛 手动测试MAC检测');
              _performAsyncMacDetection(server);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('MAC检测已启动，请到设置→调试功能→查看调试日志查看结果'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          if (widget.server == null)
            TextButton(
              onPressed: _clearForm,
              child: const Text('清空'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '基本信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '服务器名称',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.dns),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入服务器名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'IP地址或域名',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.computer),
                        hintText: '例如: 192.168.1.100',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入IP地址或域名';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: '端口',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings_ethernet),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入端口号';
                        }
                        final port = int.tryParse(value.trim());
                        if (port == null || port < 1 || port > 65535) {
                          return '请输入有效的端口号 (1-65535)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _macAddressController,
                            decoration: const InputDecoration(
                              labelText: 'MAC地址 (可选)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.network_check),
                              hintText: '例如: AA:BB:CC:DD:EE:FF',
                              helperText: '用于Wake-on-LAN功能，留空时将自动探测',
                            ),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (!Server.isValidMacAddress(value.trim())) {
                                  return 'MAC地址格式无效';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // 自动格式化MAC地址
                              final formatted = _formatMacAddressInput(value);
                              if (formatted != value) {
                                _macAddressController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isDetectingMac ? null : _manualDetectMac,
                              icon: _isDetectingMac 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.search, size: 18),
                              label: const Text(
                                '探测',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(60, 36),
                              ),
                            ),
                            const SizedBox(height: 20), // 对齐helperText空间
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '认证信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AuthType>(
                      initialValue: _authType,
                      decoration: const InputDecoration(
                        labelText: '认证方式',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AuthType.password,
                          child: Text('密码'),
                        ),
                        DropdownMenuItem(
                          value: AuthType.privateKey,
                          child: Text('私钥'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _authType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入用户名';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: _authType == AuthType.password ? '密码' : '私钥',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(_authType == AuthType.password 
                            ? Icons.lock 
                            : Icons.vpn_key),
                        suffixIcon: _authType == AuthType.password
                            ? IconButton(
                                icon: Icon(_obscurePassword 
                                    ? Icons.visibility 
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              )
                            : null,
                      ),
                      obscureText: _authType == AuthType.password ? _obscurePassword : false,
                      maxLines: _authType == AuthType.privateKey ? 5 : 1,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _authType == AuthType.password ? '请输入密码' : '请输入私钥';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveServer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.server != null ? '更新服务器' : '添加服务器'),
            ),
          ],
        ),
      ),
    );
  }
}