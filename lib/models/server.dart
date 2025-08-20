class Server {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final AuthType authType;
  final String? macAddress; // MAC地址，用于WOL功能
  bool isOnline;
  int? pingTime;

  Server({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.authType = AuthType.password,
    this.macAddress,
    this.isOnline = false,
    this.pingTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'authType': authType.name,
      'macAddress': macAddress,
      'isOnline': isOnline,
      'pingTime': pingTime,
    };
  }

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'],
      name: json['name'],
      host: json['host'],
      port: json['port'],
      username: json['username'],
      password: json['password'],
      authType: AuthType.values.firstWhere(
        (e) => e.name == json['authType'],
        orElse: () => AuthType.password,
      ),
      macAddress: json['macAddress'],
      isOnline: json['isOnline'] ?? false,
      pingTime: json['pingTime'],
    );
  }

  Server copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    AuthType? authType,
    String? macAddress,
    bool? isOnline,
    int? pingTime,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      authType: authType ?? this.authType,
      macAddress: macAddress ?? this.macAddress,
      isOnline: isOnline ?? this.isOnline,
      pingTime: pingTime ?? this.pingTime,
    );
  }

  // WOL相关功能
  bool get supportsWOL => macAddress != null && macAddress!.isNotEmpty;
  
  String? get formattedMacAddress {
    if (macAddress == null) return null;
    return formatMacAddress(macAddress!);
  }

  // 静态方法：验证MAC地址格式
  static bool isValidMacAddress(String mac) {
    final cleanMac = mac.replaceAll(RegExp(r'[:-]'), '').toUpperCase();
    return RegExp(r'^[0-9A-F]{12}$').hasMatch(cleanMac);
  }

  // 静态方法：格式化MAC地址
  static String formatMacAddress(String mac) {
    final cleanMac = mac.replaceAll(RegExp(r'[:-]'), '').toUpperCase();
    if (cleanMac.length != 12) return mac;
    
    final parts = <String>[];
    for (int i = 0; i < 12; i += 2) {
      parts.add(cleanMac.substring(i, i + 2));
    }
    return parts.join(':');
  }
}

enum AuthType {
  password,
  privateKey,
}

enum ServerStatus {
  online,
  offline,
  unknown,
}

enum PowerAction {
  shutdown,
  restart,
  wakeup,
}