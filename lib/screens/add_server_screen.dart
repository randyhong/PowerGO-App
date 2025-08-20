import 'package:flutter/material.dart';
import '../models/server.dart';
import '../services/storage_service.dart';
import '../services/server_service.dart';

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

    setState(() {
      _isLoading = true;
    });

    try {
      String? finalMacAddress = _macAddressController.text.trim();
      
      // 如果MAC地址为空，尝试自动探测
      if (finalMacAddress.isEmpty) {
        print('MAC地址为空，开始自动探测...');
        
        // 先创建临时服务器对象用于探测
        final tempServer = Server(
          id: 'temp',
          name: _nameController.text.trim(),
          host: _hostController.text.trim(),
          port: int.parse(_portController.text.trim()),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          authType: _authType,
        );
        
        // 尝试自动探测MAC地址
        final detectionResult = await _detectMacAddress(tempServer);
        if (detectionResult.success && detectionResult.macAddress != null) {
          finalMacAddress = detectionResult.macAddress!;
          // 更新UI显示探测到的MAC地址
          _macAddressController.text = finalMacAddress;
          _showInfoSnackBar('自动探测到MAC地址: $finalMacAddress');
        } else {
          _showWarningSnackBar('未能自动探测到MAC地址\n${detectionResult.error ?? "可稍后手动编辑添加"}');
        }
      }
      
      final server = Server(
        id: widget.server?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        authType: _authType,
        macAddress: finalMacAddress.isNotEmpty ? finalMacAddress : null,
      );

      if (widget.server != null) {
        await StorageService.updateServer(server);
        
        // 立即检测服务器状态
        final status = await ServerService.checkServerStatus(server);
        final updatedServer = server.copyWith(
          isOnline: status.isOnline,
          pingTime: status.pingTime,
        );
        await StorageService.updateServer(updatedServer);
        
        _showSuccessSnackBar('服务器更新成功');
        // 延迟返回上一页面
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop(true); // 传递true表示有更新
          }
        });
      } else {
        await StorageService.addServer(server);
        
        // 立即检测新添加服务器的状态
        final status = await ServerService.checkServerStatus(server);
        final updatedServer = server.copyWith(
          isOnline: status.isOnline,
          pingTime: status.pingTime,
        );
        await StorageService.updateServer(updatedServer);
        
        _showSuccessSnackBar('服务器添加成功');
        // 延迟跳转到服务器列表页
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop({'success': true, 'switchToServers': true});
          }
        });
        _clearForm();
      }
    } catch (e) {
      _showErrorSnackBar('保存失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  // MAC地址探测方法
  Future<MacDetectionResult> _detectMacAddress(Server server) async {
    setState(() {
      _isDetectingMac = true;
    });

    try {
      return await MacAddressDetector.detectMacAddress(server);
    } finally {
      setState(() {
        _isDetectingMac = false;
      });
    }
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
                      value: _authType,
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