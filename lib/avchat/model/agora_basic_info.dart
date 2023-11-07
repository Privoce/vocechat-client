import 'package:json_annotation/json_annotation.dart';

part 'agora_basic_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraBasicInfo {
  final String agoraToken;
  final String appId;
  final int uid;
  final String channelName;
  final int expiredIn;

  AgoraBasicInfo(
      {required this.agoraToken,
      required this.appId,
      required this.uid,
      required this.channelName,
      required this.expiredIn});

  factory AgoraBasicInfo.fromJson(Map<String, dynamic> json) =>
      _$AgoraBasicInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraBasicInfoToJson(this);
}
