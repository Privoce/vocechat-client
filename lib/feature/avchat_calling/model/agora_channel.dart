import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agora_channel.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraChannel extends Equatable {
  final int userCount;
  final String channelname;

  const AgoraChannel({required this.userCount, required this.channelname});

  factory AgoraChannel.fromJson(Map<String, dynamic> json) =>
      _$AgoraChannelFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraChannelToJson(this);

  @override
  List<Object?> get props => [userCount, channelname];
}
