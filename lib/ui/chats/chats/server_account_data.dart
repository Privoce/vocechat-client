import 'dart:typed_data';

import 'package:vocechat_client/dao/org_dao/userdb.dart';

class ServerAccountData {
  final Uint8List serverAvatarBytes;
  final Uint8List userAvatarBytes;
  final String serverName;
  final String serverUrl;  // 显示用的服务器URL（原始URL）
  final String? actualServerUrl; // 实际连接用的服务器URL（重定向后的URL）
  final String username;
  final String userEmail;
  final bool selected;

  final UserDbM userDbM;

  ServerAccountData(
      {required this.serverAvatarBytes,
      required this.userAvatarBytes,
      required this.serverName,
      required this.serverUrl,
      this.actualServerUrl,
      required this.username,
      required this.userEmail,
      required this.selected,
      required this.userDbM});
}
