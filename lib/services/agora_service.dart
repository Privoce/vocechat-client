import 'package:dio/dio.dart';

import 'package:vocechat_client/api/lib/agora_api.dart';
import '../api/models/token/token_agora_response.dart';
import '../dao/org_dao/chat_server.dart';

class AgoraService {
  AgoraService(this.gid, this._agoraApi, {required this.chatServerM}) {
    _agoraApi = AgoraApi(chatServerM.fullUrl);
  }

  final int? gid;
  final ChatServerM chatServerM;
  late final AgoraApi _agoraApi;

  Future<Response<TokenAgoraResponse>> renewAuthToken(gid) async {
    final res = await _agoraApi.generatesAgoraToken(gid);
    return res;
  }
}
