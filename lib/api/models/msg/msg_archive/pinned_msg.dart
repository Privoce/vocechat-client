import 'package:json_annotation/json_annotation.dart';

part 'pinned_msg.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)

/// Only consists of main message contents, do not contain replies, edited info and reactions.
class PinnedMsg {
  final int mid;
  final int createdBy;
  final int createdAt;
  final Map<String, dynamic>? properties;
  final String contentType;
  final String content;

  PinnedMsg(
      {required this.mid,
      required this.createdAt,
      required this.createdBy,
      required this.properties,
      required this.content,
      required this.contentType});

  bool get isImageMsg {
    return properties!["content_type"].split("/").first.toLowerCase() ==
        'image';
  }

  factory PinnedMsg.fromJson(Map<String, dynamic> json) =>
      _$PinnedMsgFromJson(json);

  Map<String, dynamic> toJson() => _$PinnedMsgToJson(this);
}
