import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server.dart';

class StorageService {
  static const String _serversKey = 'servers';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<List<Server>> getServers() async {
    _prefs ??= await SharedPreferences.getInstance();
    final String? serversJson = _prefs!.getString(_serversKey);
    if (serversJson == null) return [];
    
    final List<dynamic> serversList = jsonDecode(serversJson);
    return serversList.map((json) => Server.fromJson(json)).toList();
  }

  static Future<void> saveServers(List<Server> servers) async {
    _prefs ??= await SharedPreferences.getInstance();
    final String serversJson = jsonEncode(
      servers.map((server) => server.toJson()).toList(),
    );
    await _prefs!.setString(_serversKey, serversJson);
  }

  static Future<void> addServer(Server server) async {
    final servers = await getServers();
    servers.add(server);
    await saveServers(servers);
  }

  static Future<void> updateServer(Server updatedServer) async {
    final servers = await getServers();
    final index = servers.indexWhere((s) => s.id == updatedServer.id);
    if (index != -1) {
      servers[index] = updatedServer;
      await saveServers(servers);
    }
  }

  static Future<void> deleteServer(String serverId) async {
    final servers = await getServers();
    servers.removeWhere((s) => s.id == serverId);
    await saveServers(servers);
  }
}