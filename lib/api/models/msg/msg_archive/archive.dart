
import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive_msg.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive_user.dart';

part 'archive.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)

/// An [Archive], may contain multiple [ArchiveMsg]s.
class Archive {
  // ArchiveUser
  late final List<Map<String, dynamic>> _users;

  /// ArchiveMsg
  late final List<Map<String, dynamic>> _messages;
  final int numAttachments;

  Archive(
      {required List<Map<String, dynamic>> users,
      required List<Map<String, dynamic>> messages,
      required this.numAttachments}) {
    _users = users;
    _messages = messages;
  }

  List<ArchiveUser> get users {
    return _users.map((e) => ArchiveUser.fromJson(e)).toList();
  }

  List<ArchiveMsg> get messages {
    return _messages.map((e) => ArchiveMsg.fromJson(e)).toList();
  }

  factory Archive.fromJson(Map<String, dynamic> json) =>
      _$ArchiveFromJson(json);

  Map<String, dynamic> toJson() => _$ArchiveToJson(this);
}
