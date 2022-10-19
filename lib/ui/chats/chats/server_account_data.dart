import 'dart:typed_data';

import 'package:vocechat_client/dao/org_dao/userdb.dart';

class ServerAccountData {
  final Uint8List serverAvatarBytes;
  final Uint8List userAvatarBytes;
  final String serverName;
  final String serverUrl;
  final String username;
  final String userEmail;
  final bool selected;

  final UserDbM userDbM;

  ServerAccountData(
      {required this.serverAvatarBytes,
      required this.userAvatarBytes,
      required this.serverName,
      required this.serverUrl,
      required this.username,
      required this.userEmail,
      required this.selected,
      required this.userDbM});
}
