import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'agora_channel.dart';

part 'agora_channel_data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraChannelData extends Equatable {
  late final List<AgoraChannel> channels;
  final int totalSize;

  AgoraChannelData({required List<dynamic> channels, required this.totalSize}) {
    this.channels = channels.map((e) => AgoraChannel.fromJson(e)).toList();
  }

  factory AgoraChannelData.fromJson(Map<String, dynamic> json) =>
      _$AgoraChannelDataFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraChannelDataToJson(this);

  @override
  List<Object?> get props => [channels, totalSize];
}
