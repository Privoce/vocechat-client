// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';
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
    String _url = url + ':$port';
    if (tls == 0) {
      _url = 'http://' + _url;
    } else {
      _url = 'https://' + _url;
    }
    return _url;
  }

  String get fullUrlWithoutPort {
    String _url = url;
    if (tls == 0) {
      _url = 'http://' + _url;
    } else {
      _url = 'https://' + _url;
    }
    return _url;
  }

  ChatServerProperties get properties {
    return ChatServerProperties.fromJson(jsonDecode(_properties));
  }

  set properties(ChatServerProperties p) {
    _properties = jsonEncode(p);
  }

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
  static const F_createdAt = "created_at";
  static const F_updatedAt = "updated_at";
  static const F_properties = "properties";

  @override
  Map<String, Object> get values => {
        ChatServerM.F_logo: logo,
        ChatServerM.F_url: url,
        ChatServerM.F_port: port,
        ChatServerM.F_tls: tls,
        ChatServerM.F_createdAt: createdAt,
        ChatServerM.F_updatedAt: updatedAt,
        ChatServerM.F_properties: _properties,
      };

  static MMeta meta = MMeta.fromType(ChatServerM, ChatServerM.fromMap)
    ..tableName = F_tableName;

  bool setByUrl(String url) {
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

      if (m.logo.isEmpty) {
        m.logo = old.logo;
      }
      await super.update(m);
    } else {
      await super.add(m);
    }
    App.logger.info("ChatServerM saved. Id: ${m.id}");
    return m;
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

  // Future<ChatServerM?> currentServer() async {
  //   ChatServerM? chatServer = await get(await OrgSettingDao.dao.getCurrentServerId());
  //   return chatServer;
  // }

  // Future<void> updateCompanyFromServer(ChatServerM m) async {
  //   ChatClient chat = createChatClient(createClientChannel(m.tls.toTrue(), m.url, m.port));
  //   Company res = await chat.companyGet(EmptyReq(token: ""));
  //   m.serverName = res.name;
  //   m.logo = imageWebStringToBytes(res.logo);
  //   await get(await OrgSettingDao.dao.getCurrentServerId());
  //   return;
  // }
}
