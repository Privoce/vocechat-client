import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agora_token_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraTokenInfo extends Equatable {
  final String agoraToken;
  final String appId;
  final int uid;
  final String channelName;
  final int expiredIn;

  const AgoraTokenInfo(
      {required this.agoraToken,
      required this.appId,
      required this.uid,
      required this.channelName,
      required this.expiredIn});

  factory AgoraTokenInfo.fromJson(Map<String, dynamic> json) =>
      _$AgoraBasicInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraBasicInfoToJson(this);

  @override
  List<Object?> get props => [agoraToken, appId, uid, channelName, expiredIn];
}
