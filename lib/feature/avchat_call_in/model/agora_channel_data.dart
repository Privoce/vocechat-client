import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'agora_channel.dart';

part 'agora_channel_data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraChannelData extends Equatable {
  final List<AgoraChannel> channels;
  final int totalSize;

  const AgoraChannelData({required this.channels, required this.totalSize});

  factory AgoraChannelData.fromJson(Map<String, dynamic> json) =>
      _$AgoraChannelDataFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraChannelDataToJson(this);

  @override
  List<Object?> get props => [channels, totalSize];
}
