import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agora_channel_detail.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraChannelDetail extends Equatable {
  final bool channelExist;
  final int mode;
  final int total;
  final List<int> users;

  const AgoraChannelDetail({
    required this.channelExist,
    required this.mode,
    required this.total,
    required this.users,
  });

  factory AgoraChannelDetail.fromJson(Map<String, dynamic> json) =>
      _$AgoraChannelDetailFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraChannelDetailToJson(this);

  @override
  List<Object?> get props => [channelExist, mode, total, users];
}
