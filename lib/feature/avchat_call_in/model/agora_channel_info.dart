import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agora_channel_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraChannelInfo extends Equatable {
  final bool success;
  final dynamic data;

  const AgoraChannelInfo({required this.success, required this.data});

  factory AgoraChannelInfo.fromJson(Map<String, dynamic> json) =>
      _$AgoraChannelInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraChannelInfoToJson(this);

  @override
  List<Object?> get props => [success, data];
}
