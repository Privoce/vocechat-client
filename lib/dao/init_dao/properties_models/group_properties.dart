import 'package:json_annotation/json_annotation.dart';

part 'group_properties.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GroupProperties {
  late int burnAfterReadSecond;
  late bool enableMute = false;
  late int? muteExpiresAt;

  /// -1 if not initialized.
  late int readIndex;
  late String draft;

  GroupProperties(
    this.burnAfterReadSecond,
    this.enableMute,
    this.muteExpiresAt,
    this.readIndex,
    this.draft,
  );

  GroupProperties.update({
    int? burnAfterReadSecond,
    bool? enableMute,
    this.muteExpiresAt,
    int? readIndex,
    String? draft,
  }) {
    this.burnAfterReadSecond = burnAfterReadSecond ?? 0;

    this.enableMute = enableMute ?? false;

    this.readIndex = readIndex ?? -1;

    this.draft = draft ?? "";
  }

  factory GroupProperties.fromJson(Map<String, dynamic> json) =>
      _$GroupPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$GroupPropertiesToJson(this);
}
