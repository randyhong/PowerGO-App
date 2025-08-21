import 'package:flutter/material.dart';
import 'package:powergo/services/storage_service.dart';
import 'servers_screen.dart';
import 'add_server_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ServersScreenState> _serversScreenKey = GlobalKey<ServersScreenState>();
  final GlobalKey<SettingsScreenState> _settingsScreenKey = GlobalKey<SettingsScreenState>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await StorageService.init();
  }

  void _onTabTap(int index) async {
    if (index == 1) {
      // 点击添加按钮，导航到添加服务器页面
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => const AddServerScreen(),
        ),
      );
      
      // 处理返回结果
      if (result != null && result['success'] == true) {
        if (result['switchToServers'] == true) {
          // 切换到服务器列表页并刷新
          setState(() {
            _currentIndex = 0;
          });
          // 刷新服务器列表
          _serversScreenKey.currentState?.refreshServers();
        }
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onSettingsChanged() {
    // 当设置发生变化时，通知服务器页面更新
    _serversScreenKey.currentState?.onSettingsChanged();
  }

  void _onServersSettingsChanged() {
    // 当服务器页面修改了设置时，通知设置页面更新
    _settingsScreenKey.currentState?.onSettingsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ServersScreen(key: _serversScreenKey, onSettingsChanged: _onServersSettingsChanged),
          const SizedBox(), // 占位符，因为添加页面现在是独立导航
          SettingsScreen(key: _settingsScreenKey, onSettingsChanged: _onSettingsChanged),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dns),
            label: '服务器',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '添加',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}