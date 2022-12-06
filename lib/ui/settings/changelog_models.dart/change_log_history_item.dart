import 'package:json_annotation/json_annotation.dart';

part 'change_log_history_item.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChangeLogHistoryItem {
  /// The millisecond timestamp when this version is updated.
  int time;

  /// The version number.
  String version;

  /// The build number used for Android.
  int buildNum;

  /// A list of updates.
  List<dynamic> updates;

  /// An item in [logs] list in ChangeLog.
  ChangeLogHistoryItem(
      {required this.time,
      required this.version,
      required this.buildNum,
      required this.updates});

  factory ChangeLogHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$ChangeLogHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeLogHistoryItemToJson(this);
}
