import 'package:json_annotation/json_annotation.dart';

part 'change_log_latest.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChangeLogLatest {
  /// Latest version number
  String version;

  /// The build number used for Android.
  int buildNum;

  /// An item in [logs] list in ChangeLog.
  ChangeLogLatest({required this.version, required this.buildNum});

  factory ChangeLogLatest.fromJson(Map<String, dynamic> json) =>
      _$ChangeLogLatestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeLogLatestToJson(this);
}
