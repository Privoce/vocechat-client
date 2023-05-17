import 'package:json_annotation/json_annotation.dart';

part 'archive_msg.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)

/// Single archive message item in an [Archive].
class ArchiveMsg {
  final int fromUser;
  final int createdAt;
  final int mid;
  final Map<String, dynamic> source;
  final Map<String, dynamic>? properties;
  final String contentType;
  final String? content;
  final int? fileId;
  final int? thumbnailId;

  ArchiveMsg(
      {required this.fromUser,
      required this.createdAt,
      required this.mid,
      required this.source,
      this.properties,
      required this.contentType,
      this.content,
      this.fileId,
      this.thumbnailId});

  bool get isImageMsg {
    return properties?["content_type"]?.split("/").first.toLowerCase() ==
        'image';
  }

  String get fileName {
    return properties?["name"] ?? "";
  }

  factory ArchiveMsg.fromJson(Map<String, dynamic> json) =>
      _$ArchiveMsgFromJson(json);

  Map<String, dynamic> toJson() => _$ArchiveMsgToJson(this);
}
