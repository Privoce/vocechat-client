import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/ui/settings/changelog_models.dart/change_log_history_item.dart';
import 'package:vocechat_client/ui/settings/changelog_models.dart/change_log_latest.dart';

part 'change_log.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChangeLog {
  /// The latest version info.
  ChangeLogLatest latest;

  /// A list of past update logs.
  List<ChangeLogHistoryItem> logs;

  /// An item in [logs] list in ChangeLog.
  ChangeLog({required this.latest, required this.logs});

  factory ChangeLog.fromJson(Map<String, dynamic> json) =>
      _$ChangeLogFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeLogToJson(this);
}
