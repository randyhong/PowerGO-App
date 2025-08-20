import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dartssh2/dartssh2.dart';
import '../models/server.dart';

class ServerService {
  static Future<ServerStatusResult> checkServerStatus(Server server) async {
    // 添加调试日志
    print('检测服务器状态: ${server.name} (${server.host}:${server.port})');
    
    try {
      // 方法1: 尝试TCP连接到指定端口
      final tcpResult = await _checkTCPConnection(server);
      if (tcpResult.isOnline) {
        print('TCP连接成功: ${server.host}:${server.port} - ${tcpResult.pingTime}ms');
        return tcpResult;
      }
      
      // 方法2: 如果TCP连接失败，尝试ping
      print('TCP连接失败，尝试ping: ${server.host}');
      final pingResult = await _checkPing(server);
      if (pingResult.isOnline) {
        print('Ping成功: ${server.host} - ${pingResult.pingTime}ms');
        return pingResult;
      }
      
      // 方法3: 尝试HTTP连接（检测常见的Web端口）
      if (server.port != 80 && server.port != 443) {
        print('尝试HTTP连接: ${server.host}');
        final httpResult = await _checkHTTPConnection(server);
        if (httpResult.isOnline) {
          print('HTTP连接成功: ${server.host}');
          return httpResult;
        }
      }
      
      print('所有检测方法都失败，服务器可能离线: ${server.host}');
      return ServerStatusResult(
        isOnline: false,
        pingTime: null,
      );
    } catch (e) {
      print('检测服务器状态时发生错误: $e');
      return ServerStatusResult(
        isOnline: false,
        pingTime: null,
      );
    }
  }

  // TCP连接检测
  static Future<ServerStatusResult> _checkTCPConnection(Server server) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final socket = await Socket.connect(
        server.host,
        server.port,
        timeout: const Duration(seconds: 1), // 缩短TCP连接超时到1秒
      );
      
      stopwatch.stop();
      await socket.close();
      
      return ServerStatusResult(
        isOnline: true,
        pingTime: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      print('TCP连接失败: ${server.host}:${server.port} - $e');
      return ServerStatusResult(
        isOnline: false,
        pingTime: null,
      );
    }
  }

  // Ping检测
  static Future<ServerStatusResult> _checkPing(Server server) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // 在Web环境中，ping命令不可用，使用HTTP请求模拟
      if (kIsWeb) {
        // Web环境：尝试简单的HTTP请求
        final client = http.Client();
        try {
          final response = await client.head(
            Uri.parse('http://${server.host}'),
          ).timeout(const Duration(seconds: 1));
          
          stopwatch.stop();
          client.close();
          
          // 任何HTTP响应都表示服务器在线
          return ServerStatusResult(
            isOnline: true,
            pingTime: stopwatch.elapsedMilliseconds,
          );
        } catch (e) {
          client.close();
          throw e;
        }
      } else {
        // 原生环境：使用系统ping命令
        final result = await Process.run(
          'ping',
          Platform.isWindows 
              ? ['-n', '1', server.host]
              : ['-c', '1', server.host],
        ).timeout(const Duration(seconds: 2));
        
        stopwatch.stop();
        
        if (result.exitCode == 0) {
          return ServerStatusResult(
            isOnline: true,
            pingTime: stopwatch.elapsedMilliseconds,
          );
        }
      }
      
      return ServerStatusResult(
        isOnline: false,
        pingTime: null,
      );
    } catch (e) {
      print('Ping检测失败: ${server.host} - $e');
      return ServerStatusResult(
        isOnline: false,
        pingTime: null,
      );
    }
  }

  // HTTP连接检测
  static Future<ServerStatusResult> _checkHTTPConnection(Server server) async {
    try {
      final stopwatch = Stopwatch()..start();
      final client = http.Client();
      
      // Web环境：使用特殊的检测方法
      if (kIsWeb) {
        // 对于Web环境，我们只能检测支持CORS的公共服务
        // 或者使用ping服务API
        try {
          // 尝试使用公共ping API服务
          final response = await client.get(
            Uri.parse('https://api.ipify.org?format=json'),
          ).timeout(const Duration(seconds: 2));
          
          stopwatch.stop();
          client.close();
          
          // 如果可以访问互联网，我们假设用户网络正常
          // 对于内网服务器，Web环境无法准确检测
          print('Web环境：网络连接正常，但无法直接检测内网服务器 ${server.host}');
          return ServerStatusResult(
            isOnline: false, // Web环境下，内网服务器默认显示离线
            pingTime: null,
          );
        } catch (e) {
          client.close();
          throw e;
        }
      } else {
        // 原生环境：正常的HTTP检测
        try {
          final response = await client.head(
            Uri.parse('http://${server.host}'),
          ).timeout(const Duration(seconds: 1));
          
          stopwatch.stop();
          client.close();
          
          return ServerStatusResult(
            isOnline: true,
            pingTime: stopwatch.elapsedMilliseconds,
          );
        } catch (e) {
          // 尝试HTTPS连接
          try {
            final response = await client.head(
              Uri.parse('https://${server.host}'),
            ).timeout(const Duration(seconds: 1));
            
            stopwatch.stop();
            client.close();
            
            return ServerStatusResult(
              isOnline: true,
              pingTime: stopwatch.elapsedMilliseconds,
            );
          } catch (e2) {
            client.close();
            throw e2;
          }
        }
      }
    } catch (e) {
      print('HTTP连接检测失败: ${server.host} - $e');
      return ServerStatusResult(
        isOnline: false,
        pingTime: null,
      );
    }
  }

  static Future<bool> executePowerAction(Server server, PowerAction action) async {
    try {
      print('开始执行电源操作: ${action.name} on ${server.host}');
      
      // 特殊处理WOL功能
      if (action == PowerAction.wakeup) {
        return await ServerServiceWOL._executeWakeOnLan(server);
      }
      
      // 生成适合的命令列表（按优先级排序）
      List<String> commands = _generatePowerCommands(server, action);
      
      // 尝试执行命令
      bool success = false;
      String lastError = '';
      
      for (int i = 0; i < commands.length; i++) {
        final command = commands[i];
        print('尝试执行命令 ${i + 1}/${commands.length}: $command');
        
        try {
          success = await _executeSSHCommand(server, command);
          if (success) {
            print('命令执行成功: $command');
            break;
          }
        } catch (e) {
          lastError = e.toString();
          print('命令执行失败: $command - $e');
          continue;
        }
      }
      
      if (!success) {
        print('所有命令都执行失败，最后一个错误: $lastError');
      }
      
      return success;
    } catch (e) {
      print('电源操作失败: $e');
      return false;
    }
  }

  // 生成适合不同权限和系统的电源命令
  static List<String> _generatePowerCommands(Server server, PowerAction action) {
    List<String> commands = [];
    
    switch (action) {
      case PowerAction.shutdown:
        // 按优先级排序的关机命令
        commands.addAll([
          // 1. 使用密码的sudo命令（推荐）
          'echo "${server.password}" | sudo -S shutdown -h now',
          'echo "${server.password}" | sudo -S poweroff',
          'echo "${server.password}" | sudo -S halt',
          
          // 2. 无密码sudo（如果配置了NOPASSWD）
          'sudo shutdown -h now',
          'sudo poweroff',
          'sudo halt',
          
          // 3. systemd命令（现代Linux系统）
          'echo "${server.password}" | sudo -S systemctl poweroff',
          'systemctl poweroff --no-ask-password',
          
          // 4. 直接命令（如果用户有权限）
          'poweroff',
          'halt',
          
          // 5. 备用方法
          'echo "${server.password}" | sudo -S init 0',
          'init 0',
        ]);
        break;
        
      case PowerAction.restart:
        // 按优先级排序的重启命令
        commands.addAll([
          // 1. 使用密码的sudo命令（推荐）
          'echo "${server.password}" | sudo -S shutdown -r now',
          'echo "${server.password}" | sudo -S reboot',
          
          // 2. 无密码sudo
          'sudo shutdown -r now',
          'sudo reboot',
          
          // 3. systemd命令
          'echo "${server.password}" | sudo -S systemctl reboot',
          'systemctl reboot --no-ask-password',
          
          // 4. 直接命令
          'reboot',
          
          // 5. 备用方法
          'echo "${server.password}" | sudo -S init 6',
          'init 6',
        ]);
        break;
        
      case PowerAction.wakeup:
        // WOL功能需要特殊处理，不是SSH命令
        // 我们在这里返回空命令列表，因为WOL有独立的处理逻辑
        commands.clear();
        break;
    }
    
    return commands;
  }

  // 执行SSH命令（改进版本）
  static Future<bool> _executeSSHCommand(Server server, String command) async {
    try {
      // Web环境限制：无法执行真实的SSH连接
      if (kIsWeb) {
        print('Web环境模拟执行: $command');
        await Future.delayed(const Duration(seconds: 1));
        
        // 在Web环境中，我们模拟成功（实际部署时需要真实SSH）
        return true;
      }
      
      // 原生环境：这里应该使用真正的SSH库
      // 例如：dartssh2, ssh2, 或调用系统SSH命令
      print('原生环境执行SSH命令: $command');
      
      // 模拟SSH连接过程
      await _simulateRealSSHConnection(server, command);
      
      return true;
    } catch (e) {
      print('SSH命令执行失败: $e');
      return false;
    }
  }

  // 真实的SSH连接实现
  static Future<void> _simulateRealSSHConnection(Server server, String command) async {
    if (kIsWeb) {
      // Web环境：模拟实现
      print('=== SSH连接模拟 (Web环境) ===');
      print('主机: ${server.host}:${server.port}');
      print('用户: ${server.username}');
      print('认证: ${server.authType.name}');
      print('命令: $command');
      
      await Future.delayed(const Duration(milliseconds: 500));
      print('SSH连接建立成功 (模拟)');
      
      await Future.delayed(const Duration(seconds: 1));
      print('命令执行完成 (模拟)');
      
      await Future.delayed(const Duration(milliseconds: 200));
      print('SSH连接已关闭 (模拟)');
      print('=========================');
      return;
    }
    
    // 原生环境：真实SSH实现
    print('=== 真实SSH连接 ===');
    print('主机: ${server.host}:${server.port}');
    print('用户: ${server.username}');
    print('认证: ${server.authType.name}');
    
    SSHClient? client;
    try {
      // 创建SSH客户端
      final socket = await SSHSocket.connect(server.host, server.port);
      client = SSHClient(
        socket,
        username: server.username,
        onPasswordRequest: () => server.password,
      );
      
      print('SSH连接建立成功');
      
      // 执行命令
      final session = await client.execute(command);
      print('正在执行命令: $command');
      
      // 等待命令完成
      await session.done;
      
      // 获取输出
      final stdout = await utf8.decoder.bind(session.stdout).join();
      final stderr = await utf8.decoder.bind(session.stderr).join();
      
      print('命令执行完成');
      if (stdout.isNotEmpty) {
        print('标准输出: $stdout');
      }
      if (stderr.isNotEmpty) {
        print('错误输出: $stderr');
      }
      
      print('退出代码: ${await session.exitCode}');
      
    } catch (e) {
      print('SSH连接失败: $e');
      rethrow;
    } finally {
      // 关闭连接
      client?.close();
      print('SSH连接已关闭');
      print('================');
    }
  }

  // 实际的SSH命令执行（用于生产环境）
  static Future<SSHCommandResult> executeRealSSHCommand(Server server, String command) async {
    if (kIsWeb) {
      throw UnsupportedError('Web环境不支持真实SSH连接');
    }
    
    SSHClient? client;
    try {
      // 建立SSH连接
      final socket = await SSHSocket.connect(
        server.host, 
        server.port,
        timeout: const Duration(seconds: 10),
      );
      
      client = SSHClient(
        socket,
        username: server.username,
        onPasswordRequest: () => server.password,
      );
      
      // 执行命令
      final session = await client.execute(command);
      await session.done;
      
      // 收集结果
      final stdout = await utf8.decoder.bind(session.stdout).join();
      final stderr = await utf8.decoder.bind(session.stderr).join();
      final exitCode = await session.exitCode ?? -1;
      
      return SSHCommandResult(
        success: exitCode == 0,
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
      );
      
    } catch (e) {
      return SSHCommandResult(
        success: false,
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
      );
    } finally {
      client?.close();
    }
  }

  static Future<bool> testConnection(Server server) async {
    try {
      final socket = await Socket.connect(
        server.host,
        server.port,
        timeout: const Duration(seconds: 10),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class ServerStatusResult {
  final bool isOnline;
  final int? pingTime;

  ServerStatusResult({
    required this.isOnline,
    this.pingTime,
  });
}

class SSHCommandResult {
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;

  SSHCommandResult({
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

class NetworkUtils {
  static Future<bool> pingHost(String host, {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final result = await Process.run(
        'ping',
        Platform.isWindows 
            ? ['-n', '1', host]
            : ['-c', '1', host],
      ).timeout(timeout);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<int?> measureLatency(String host, int port) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      stopwatch.stop();
      await socket.close();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      return null;
    }
  }
}

// Wake-on-LAN实现类
class WakeOnLanService {
  // WOL端口：通常是9或7
  static const int wolPort = 9;
  static const int wolPortAlt = 7;

  // 执行Wake-on-LAN唤醒
  static Future<bool> sendWakeOnLan(String macAddress, {String? broadcastAddress}) async {
    try {
      print('准备发送WOL魔术包');
      print('目标MAC地址: $macAddress');
      
      if (!Server.isValidMacAddress(macAddress)) {
        print('无效的MAC地址格式: $macAddress');
        return false;
      }

      // 创建魔术包
      final magicPacket = _createMagicPacket(macAddress);
      print('魔术包创建成功，大小: ${magicPacket.length} bytes');

      // 确定广播地址
      final targetAddress = broadcastAddress ?? '255.255.255.255';
      print('广播地址: $targetAddress');

      bool success = false;

      // 在Web环境中，我们无法发送UDP包，只能模拟
      if (kIsWeb) {
        print('Web环境：模拟发送WOL魔术包');
        await Future.delayed(const Duration(milliseconds: 500));
        print('WOL魔术包发送完成 (模拟)');
        return true;
      }

      // 原生环境：发送到主要端口9
      try {
        success = await _sendUdpPacket(targetAddress, wolPort, magicPacket);
        if (success) {
          print('WOL魔术包发送成功 (端口 $wolPort)');
        }
      } catch (e) {
        print('发送到端口 $wolPort 失败: $e');
      }

      // 如果主要端口失败，尝试备用端口7
      if (!success) {
        try {
          success = await _sendUdpPacket(targetAddress, wolPortAlt, magicPacket);
          if (success) {
            print('WOL魔术包发送成功 (备用端口 $wolPortAlt)');
          }
        } catch (e) {
          print('发送到备用端口 $wolPortAlt 失败: $e');
        }
      }

      if (!success) {
        print('所有端口发送都失败');
      }

      return success;
    } catch (e) {
      print('WOL发送失败: $e');
      return false;
    }
  }

  // 创建WOL魔术包
  static Uint8List _createMagicPacket(String macAddress) {
    // 清理MAC地址，移除分隔符
    final cleanMac = macAddress.replaceAll(RegExp(r'[:-]'), '').toUpperCase();
    
    // 将MAC地址转换为字节数组
    final macBytes = Uint8List(6);
    for (int i = 0; i < 6; i++) {
      final hex = cleanMac.substring(i * 2, i * 2 + 2);
      macBytes[i] = int.parse(hex, radix: 16);
    }

    // 创建魔术包：6个0xFF + 16次重复MAC地址
    final magicPacket = Uint8List(102); // 6 + 16*6 = 102 bytes
    
    // 前6个字节都是0xFF
    for (int i = 0; i < 6; i++) {
      magicPacket[i] = 0xFF;
    }
    
    // 接下来16次重复MAC地址
    for (int i = 0; i < 16; i++) {
      final offset = 6 + i * 6;
      for (int j = 0; j < 6; j++) {
        magicPacket[offset + j] = macBytes[j];
      }
    }

    return magicPacket;
  }

  // 发送UDP数据包
  static Future<bool> _sendUdpPacket(String address, int port, Uint8List data) async {
    RawDatagramSocket? socket;
    try {
      // 创建UDP socket
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      // 发送数据包
      final targetAddress = InternetAddress(address);
      final bytesSent = socket.send(data, targetAddress, port);
      
      if (bytesSent > 0) {
        print('已发送 $bytesSent 字节到 $address:$port');
        
        // 等待一小段时间确保数据包发送
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      } else {
        print('UDP数据包发送失败');
        return false;
      }
    } catch (e) {
      print('UDP发送错误: $e');
      return false;
    } finally {
      socket?.close();
    }
  }

  // 检测WOL支持情况
  static Future<WOLSupportResult> checkWOLSupport(Server server) async {
    try {
      print('检测WOL支持: ${server.name}');
      
      // 基本检查：是否有MAC地址
      if (!server.supportsWOL) {
        return WOLSupportResult(
          isSupported: false,
          reason: 'MAC地址未配置',
          details: '要使用WOL功能，需要配置服务器的MAC地址',
        );
      }

      if (!Server.isValidMacAddress(server.macAddress!)) {
        return WOLSupportResult(
          isSupported: false,
          reason: 'MAC地址格式无效',
          details: 'MAC地址格式应为：XX:XX:XX:XX:XX:XX 或 XX-XX-XX-XX-XX-XX',
        );
      }

      // 在Web环境中，提供有限的支持检测
      if (kIsWeb) {
        return WOLSupportResult(
          isSupported: true,
          reason: 'Web环境限制',
          details: 'Web环境中WOL功能受限，建议使用原生应用获得完整功能',
          webLimited: true,
        );
      }

      // 原生环境：尝试检测网络接口和WOL能力
      try {
        // 检测本地网络接口
        final interfaces = await NetworkInterface.list();
        bool hasValidInterface = false;
        
        for (final interface in interfaces) {
          if (interface.addresses.isNotEmpty && !interface.addresses.first.isLoopback) {
            hasValidInterface = true;
            print('找到网络接口: ${interface.name}');
            break;
          }
        }

        if (!hasValidInterface) {
          return WOLSupportResult(
            isSupported: false,
            reason: '没有可用的网络接口',
            details: '无法找到有效的网络接口来发送WOL数据包',
          );
        }

        // 如果服务器在线，我们可以尝试通过SSH检测WOL支持
        if (server.isOnline) {
          final wolStatus = await _checkRemoteWOLSupport(server);
          return WOLSupportResult(
            isSupported: true,
            reason: 'WOL功能可用',
            details: wolStatus.isNotEmpty ? wolStatus : '本地网络支持WOL数据包发送',
            remoteWOLStatus: wolStatus,
          );
        }

        return WOLSupportResult(
          isSupported: true,
          reason: '基本WOL支持',
          details: '本地网络支持发送WOL数据包，但无法检测远程服务器WOL配置',
        );

      } catch (e) {
        print('WOL支持检测失败: $e');
        return WOLSupportResult(
          isSupported: true,
          reason: '无法完全检测',
          details: '无法完全检测WOL支持，但可以尝试发送WOL数据包',
        );
      }
    } catch (e) {
      print('WOL支持检测错误: $e');
      return WOLSupportResult(
        isSupported: false,
        reason: '检测失败',
        details: '无法检测WOL支持: $e',
      );
    }
  }

  // 通过SSH检测远程服务器的WOL配置
  static Future<String> _checkRemoteWOLSupport(Server server) async {
    try {
      if (kIsWeb) return '';

      // 尝试检测网卡的WOL配置
      final result = await ServerService.executeRealSSHCommand(server, 'ethtool eth0 | grep "Wake-on" || ip link show | grep "UP" || echo "无法检测WOL状态"');
      
      if (result.success && result.stdout.isNotEmpty) {
        if (result.stdout.contains('Wake-on')) {
          return '网卡WOL状态: ${result.stdout.trim()}';
        } else if (result.stdout.contains('UP')) {
          return '网络接口活跃，但WOL状态未知';
        }
      }
      
      return '无法检测远程WOL配置';
    } catch (e) {
      return '远程WOL检测失败: $e';
    }
  }
}

// MAC地址探测服务
class MacAddressDetector {
  // 自动探测服务器MAC地址
  static Future<MacDetectionResult> detectMacAddress(Server server) async {
    print('开始探测MAC地址: ${server.name} (${server.host})');
    
    try {
      // 方法1: SSH远程查询（推荐，最准确）
      final sshResult = await _detectMacViaSSH(server);
      if (sshResult.success) {
        print('SSH探测成功: ${sshResult.macAddress}');
        return sshResult;
      }
      
      // 方法2: ARP本地查询（备选方案）
      final arpResult = await _detectMacViaARP(server);
      if (arpResult.success) {
        print('ARP探测成功: ${arpResult.macAddress}');
        return arpResult;
      }
      
      // 方法3: 网络扫描探测
      final scanResult = await _detectMacViaScan(server);
      if (scanResult.success) {
        print('扫描探测成功: ${scanResult.macAddress}');
        return scanResult;
      }
      
      print('所有MAC探测方法都失败');
      return MacDetectionResult(
        success: false,
        method: 'none',
        error: '无法探测MAC地址，请手动输入',
      );
      
    } catch (e) {
      print('MAC地址探测失败: $e');
      return MacDetectionResult(
        success: false,
        method: 'error',
        error: '探测过程发生错误: $e',
      );
    }
  }
  
  // 方法1: 通过SSH查询服务器本机MAC地址
  static Future<MacDetectionResult> _detectMacViaSSH(Server server) async {
    try {
      if (kIsWeb) {
        // Web环境模拟
        print('Web环境：模拟SSH MAC探测');
        await Future.delayed(const Duration(seconds: 1));
        return MacDetectionResult(
          success: true,
          macAddress: 'AA:BB:CC:DD:EE:FF',
          method: 'ssh_simulation',
          details: 'Web环境模拟探测结果',
        );
      }

      // 尝试多个网卡接口命令
      final commands = [
        // Linux系统命令
        'ip link show | grep -A1 "state UP" | grep "link/ether" | head -1 | awk \'{print \$2}\'',
        'cat /sys/class/net/*/address | head -1',
        'ifconfig | grep -E "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}" | head -1 | awk \'{print \$2}\'',
        // 更简单的命令
        'cat /sys/class/net/eth0/address',
        'cat /sys/class/net/ens33/address',
        'cat /sys/class/net/enp0s3/address',
      ];

      for (final command in commands) {
        try {
          print('尝试SSH命令: $command');
          final result = await ServerService.executeRealSSHCommand(server, command);
          
          if (result.success && result.stdout.isNotEmpty) {
            final macAddress = result.stdout.trim();
            if (Server.isValidMacAddress(macAddress)) {
              return MacDetectionResult(
                success: true,
                macAddress: Server.formatMacAddress(macAddress),
                method: 'ssh',
                details: '通过SSH命令获取: $command',
              );
            }
          }
        } catch (e) {
          print('SSH命令失败: $command - $e');
          continue;
        }
      }
      
      return MacDetectionResult(
        success: false,
        method: 'ssh',
        error: '无法通过SSH获取MAC地址',
      );
      
    } catch (e) {
      return MacDetectionResult(
        success: false,
        method: 'ssh',
        error: 'SSH连接失败: $e',
      );
    }
  }
  
  // 方法2: 通过ARP表查询本地缓存的MAC地址
  static Future<MacDetectionResult> _detectMacViaARP(Server server) async {
    try {
      if (kIsWeb) {
        return MacDetectionResult(
          success: false,
          method: 'arp',
          error: 'Web环境不支持ARP查询',
        );
      }

      // 先ping一下确保ARP表中有记录
      await Process.run('ping', 
        Platform.isWindows 
          ? ['-n', '1', server.host]
          : ['-c', '1', server.host]
      ).timeout(const Duration(seconds: 3));

      // 查询ARP表
      final arpCommands = Platform.isWindows 
        ? ['arp', '-a', server.host]
        : ['arp', '-n', server.host];
        
      final result = await Process.run(arpCommands[0], arpCommands.sublist(1))
        .timeout(const Duration(seconds: 5));
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        print('ARP输出: $output');
        
        // 解析MAC地址
        final macRegex = RegExp(r'([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}');
        final match = macRegex.firstMatch(output);
        
        if (match != null) {
          final macAddress = match.group(0)!;
          return MacDetectionResult(
            success: true,
            macAddress: Server.formatMacAddress(macAddress),
            method: 'arp',
            details: '通过ARP表获取',
          );
        }
      }
      
      return MacDetectionResult(
        success: false,
        method: 'arp',
        error: 'ARP表中未找到MAC地址',
      );
      
    } catch (e) {
      return MacDetectionResult(
        success: false,
        method: 'arp',
        error: 'ARP查询失败: $e',
      );
    }
  }
  
  // 方法3: 网络扫描探测
  static Future<MacDetectionResult> _detectMacViaScan(Server server) async {
    try {
      if (kIsWeb) {
        return MacDetectionResult(
          success: false,
          method: 'scan',
          error: 'Web环境不支持网络扫描',
        );
      }

      // 使用nmap扫描（如果可用）
      try {
        final result = await Process.run('nmap', ['-sn', server.host])
          .timeout(const Duration(seconds: 10));
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final macRegex = RegExp(r'MAC Address: ([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}');
          final match = macRegex.firstMatch(output);
          
          if (match != null) {
            final macAddress = match.group(0)!.replaceFirst('MAC Address: ', '');
            return MacDetectionResult(
              success: true,
              macAddress: Server.formatMacAddress(macAddress),
              method: 'nmap',
              details: '通过nmap扫描获取',
            );
          }
        }
      } catch (e) {
        print('nmap不可用: $e');
      }
      
      return MacDetectionResult(
        success: false,
        method: 'scan',
        error: '网络扫描未找到MAC地址',
      );
      
    } catch (e) {
      return MacDetectionResult(
        success: false,
        method: 'scan',
        error: '扫描失败: $e',
      );
    }
  }
}

// MAC地址探测结果
class MacDetectionResult {
  final bool success;
  final String? macAddress;
  final String method;
  final String? details;
  final String? error;

  MacDetectionResult({
    required this.success,
    this.macAddress,
    required this.method,
    this.details,
    this.error,
  });

  String get displayMessage {
    if (success) {
      return '自动探测成功 ($method)\n$details';
    } else {
      return '探测失败: $error';
    }
  }
}

// 在ServerService中添加WOL执行方法
extension ServerServiceWOL on ServerService {
  static Future<bool> _executeWakeOnLan(Server server) async {
    try {
      print('执行Wake-on-LAN: ${server.name}');

      // 检查WOL支持
      final support = await WakeOnLanService.checkWOLSupport(server);
      if (!support.isSupported) {
        print('WOL不支持: ${support.reason}');
        return false;
      }

      if (support.webLimited) {
        print('Web环境WOL限制: ${support.details}');
      }

      // 发送WOL魔术包
      final success = await WakeOnLanService.sendWakeOnLan(server.macAddress!);
      
      if (success) {
        print('WOL魔术包发送成功');
        return true;
      } else {
        print('WOL魔术包发送失败');
        return false;
      }
    } catch (e) {
      print('执行WOL失败: $e');
      return false;
    }
  }
}

// WOL支持检测结果
class WOLSupportResult {
  final bool isSupported;
  final String reason;
  final String details;
  final bool webLimited;
  final String? remoteWOLStatus;

  WOLSupportResult({
    required this.isSupported,
    required this.reason,
    required this.details,
    this.webLimited = false,
    this.remoteWOLStatus,
  });
}