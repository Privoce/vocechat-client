// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:vocechat_client/api/models/admin/system/sys_common_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/org_dao/properties_models/chat_server_properties.dart';

/// Local record of server visit history.
/// Used for server page login records
class ChatServerM with M {
  Uint8List logo = Uint8List(0);

  // ip or url, without port number.
  String url = '';

  int port = -1;

  int tls = 0;

  String serverId = "";

  /// Timestamp this server was created at in this App.
  @override
  int createdAt = 0;

  /// Timestamp this server was visited at in this App.
  int updatedAt = 0;

  String _properties = "";

  String get serverUnderscoreName {
    return url.replaceAll('.', '_');
  }

  String get fullUrl {
    String url0 = '$url:$port';
    if (tls == 0) {
      url0 = 'http://$url0';
    } else {
      url0 = 'https://$url0';
    }
    return url0;
  }

  String get fullUrlWithoutPort {
    String url0 = url;
    if (tls == 0) {
      url0 = 'http://$url0';
    } else {
      url0 = 'https://$url0';
    }
    return url0;
  }

  ChatServerM copywith({
    Uint8List? logo,
    String? url,
    int? port,
    int? tls,
    String? serverId,
    int? createdAt,
    int? updatedAt,
    String? properties,
  }) {
    return ChatServerM.item(
      logo ?? this.logo,
      url ?? this.url,
      port ?? this.port,
      tls ?? this.tls,
      createdAt ?? this.createdAt,
      updatedAt ?? this.updatedAt,
      properties ?? _properties,
    );
  }

  ChatServerProperties get properties {
    return ChatServerProperties.fromJson(jsonDecode(_properties));
  }

  set properties(ChatServerProperties p) {
    _properties = jsonEncode(p);
  }

  // ChatServerProperties addProperty({AdminLoginConfig? loginConfig,  )

  ChatServerM();

  ChatServerM.item(this.logo, this.url, this.port, this.tls, this.createdAt,
      this.updatedAt, this._properties);

  static ChatServerM fromMap(Map<String, dynamic> map) {
    ChatServerM m = ChatServerM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_logo)) {
      m.logo = map[F_logo];
    }
    if (map.containsKey(F_url)) {
      m.url = map[F_url];
    }
    if (map.containsKey(F_port)) {
      m.port = map[F_port];
    }
    if (map.containsKey(F_tls)) {
      m.tls = map[F_tls];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    if (map.containsKey(F_updatedAt)) {
      m.updatedAt = map[F_updatedAt];
    }
    if (map.containsKey(F_properties)) {
      m._properties = map[F_properties];
    }

    return m;
  }

  static const F_tableName = 'chat_server';
  static const F_logo = "logo";
  static const F_url = "url";
  static const F_port = "port";
  static const F_tls = "tls";
  static const F_serverId = "server_id";
  static const F_createdAt = "created_at";
  static const F_updatedAt = "updated_at";
  static const F_properties = "properties";

  @override
  Map<String, Object> get values => {
        ChatServerM.F_logo: logo,
        ChatServerM.F_url: url,
        ChatServerM.F_port: port,
        ChatServerM.F_tls: tls,
        ChatServerM.F_serverId: serverId,
        ChatServerM.F_createdAt: createdAt,
        ChatServerM.F_updatedAt: updatedAt,
        ChatServerM.F_properties: _properties,
      };

  static MMeta meta = MMeta.fromType(ChatServerM, ChatServerM.fromMap)
    ..tableName = F_tableName;

  bool setByUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        return false;
      }
      // name = url;
      this.url = uri.host;
      if (url.isEmpty) {
        url = '127.0.0.1';
      }
      port = uri.port;
      if (uri.scheme == 'https') {
        tls = 1;
      } else {
        tls = 0;
      }
      // id = url;
      createdAt = DateTime.now().millisecondsSinceEpoch;
      return true;
    } catch (e) {
      App.logger.warning(e);
      return false;
    }
  }
}

class ChatServerDao extends OrgDao<ChatServerM> {
  static final ChatServerDao dao = ChatServerDao._p();

  ChatServerDao._p() {
    ChatServerM.meta;
  }

  Future<ChatServerM> addOrUpdate(ChatServerM m) async {
    ChatServerM? old =
        await first(where: '${ChatServerM.F_url} = ?', whereArgs: [m.url]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      m.serverId = old.serverId;

      if (m.logo.isEmpty) {
        m.logo = old.logo;
      }
      await super.update(m);
    } else {
      await super.add(m);
    }
    App.logger.info(
        "ChatServerM saved. Id: ${m.id}, serverId: ${m.serverId}, common info: ${m.properties.commonInfo?.toJson()}");
    return m;
  }

  Future<ChatServerM?> updateServerId(String serverId) async {
    // ChatServerM? old = await first();
    ChatServerM? old = await getServerById(App.app.chatServerM.id);
    if (old != null) {
      old.serverId = serverId;
      await super.update(old);
    }
    return old;
  }

  Future<ChatServerM?> updateOrgInfo(
      {String? name, String? des, Uint8List? logoBytes}) async {
    ChatServerM? old = await getServerById(App.app.chatServerM.id);
    if (old != null) {
      final properties = old.properties;
      if (name != null) {
        properties.serverName = name;
      }
      if (des != null) {
        properties.description = des;
      }
      if (logoBytes != null) {
        old.logo = logoBytes;
      }

      old.properties = properties;
      await super.update(old);
    }
    return old;
  }

  Future<ChatServerM?> updateCommonInfo(
      AdminSystemCommonInfo commonInfo) async {
    ChatServerM? old = await getServerById(App.app.chatServerM.id);
    if (old != null) {
      final oldInfo = old.properties.commonInfo;

      AdminSystemCommonInfo newInfo = AdminSystemCommonInfo(
        showUserOnlineStatus:
            commonInfo.showUserOnlineStatus ?? oldInfo?.showUserOnlineStatus,
        contactVerificationEnable: commonInfo.contactVerificationEnable ??
            oldInfo?.contactVerificationEnable,
        chatLayoutMode: commonInfo.chatLayoutMode ?? oldInfo?.chatLayoutMode,
        maxFileExpiryMode:
            commonInfo.maxFileExpiryMode ?? oldInfo?.maxFileExpiryMode,
      );

      old.properties = old.properties..commonInfo = newInfo;
      await super.update(old);
    }
    return old;
  }

  Future<ChatServerM> updateUpdatedAt(ChatServerM m, int updatedAt) async {
    ChatServerM? old =
        await first(where: '${ChatServerM.F_url} = ?', whereArgs: [m.url]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      m.updatedAt = updatedAt;
      m._properties = old._properties;
      if (m.logo.isEmpty) {
        m.logo = old.logo;
      }
      await super.update(m);
    } else {
      await super.add(m);
    }
    App.logger.info("ChatServerM updatedAt saved. Id: ${m.id}");
    return m;
  }

  /// Get a list of servers
  ///
  /// Result shown in
  /// 1. createdTs, descending order
  Future<List<ChatServerM>?> getServerList() async {
    String orderBy = "${ChatServerM.F_createdAt} DESC";
    return super.list(orderBy: orderBy);
  }

  Future<ChatServerM?> getServerByUrl(String url) async {
    return super.first(where: "${ChatServerM.F_url} = ?", whereArgs: [url]);
  }

  Future<ChatServerM?> getServerById(String id) async {
    return super.get(id);
  }
}
