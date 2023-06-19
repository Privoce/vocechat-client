import 'package:json_annotation/json_annotation.dart';

part 'agora_token_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraTokenResponse {
  final String agoraToken;
  final String appId;
  final int uid;
  final String channelName;
  final int expiredIn;

  AgoraTokenResponse(
      {required this.agoraToken,
      required this.appId,
      required this.uid,
      required this.channelName,
      required this.expiredIn});

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$AgoraTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraTokenResponseToJson(this);
}
