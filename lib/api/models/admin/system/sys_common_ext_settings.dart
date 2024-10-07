import 'package:json_annotation/json_annotation.dart';

part 'sys_common_ext_settings.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AdminSystemCommonExtSettings {
  final bool? onlyAdminCanSeeChannelMembers;

  AdminSystemCommonExtSettings({
    this.onlyAdminCanSeeChannelMembers,
  });

  factory AdminSystemCommonExtSettings.fromJson(Map<String, dynamic> json) =>
      _$AdminSystemCommonExtSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSystemCommonExtSettingsToJson(this);
}
