import 'package:json_annotation/json_annotation.dart';

part 'token_agora_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TokenAgoraResponse {
  final String agoraToken;
  final String appId;
  final int uid;
  final String channelName;
  final int expiredIn;

  TokenAgoraResponse(
      this.agoraToken, this.appId, this.uid, this.channelName, this.expiredIn);

  factory TokenAgoraResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenAgoraResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenAgoraResponseToJson(this);
}
