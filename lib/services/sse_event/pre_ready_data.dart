import 'dart:convert';

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/services/sse_event/sse_event_consts.dart';

class PreReadyData {
  final List<dynamic> _usersLog = [];
  final List<dynamic> _messages = [];
  final List<dynamic> _relatedGroups = [];

  List<dynamic> get usersLog => _usersLog;
  List<dynamic> get messages => _messages;
  List<dynamic> get relatedGroups => _relatedGroups;

  void addUsersLog(dynamic event) {
    try {
      final map = jsonDecode(event) as Map<String, dynamic>;
      assert(map["type"] == sseUsersLog);

      _usersLog.add(event);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void addMessage(dynamic event) {
    try {
      final map = jsonDecode(event) as Map<String, dynamic>;
      assert(map["type"] == sseChat);

      _messages.add(event);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void addRelatedGroup(dynamic event) {
    try {
      final map = jsonDecode(event) as Map<String, dynamic>;
      assert(map["type"] == sseRelatedGroups);

      _relatedGroups.add(event);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void clearUsersLog() => _usersLog.clear();
  void clearMessages() => _messages.clear();
  void clearRelatedGroups() => _relatedGroups.clear();

  void clearAll() {
    clearUsersLog();
    clearMessages();
    clearRelatedGroups();
  }
}
