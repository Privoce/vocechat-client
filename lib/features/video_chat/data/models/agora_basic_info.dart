import 'package:vocechat_client/features/video_chat/domain/entities/agora_basic_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agora_basic_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraBasicInfoModel extends AgoraBasicInfoEntity {
  const AgoraBasicInfoModel(
      {required super.agoraToken,
      required super.appId,
      required super.uid,
      required super.channelName,
      required super.expiredIn});

  factory AgoraBasicInfoModel.fromJson(Map<String, dynamic> json) =>
      _$AgoraBasicInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraBasicInfoModelToJson(this);
}
