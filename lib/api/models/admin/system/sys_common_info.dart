import 'package:json_annotation/json_annotation.dart';

part 'sys_common_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AdminSystemCommonInfo {
  final bool? showUserOnlineStatus;
  final bool? contactVerificationEnable;
  final String? chatLayoutMode;
  final String? maxFileExpiryMode;

  AdminSystemCommonInfo({
    this.showUserOnlineStatus = true,
    this.contactVerificationEnable = true,
    this.chatLayoutMode = "Left",
    this.maxFileExpiryMode = "Off",
  });

  factory AdminSystemCommonInfo.fromJson(Map<String, dynamic> json) =>
      _$AdminSystemCommonInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSystemCommonInfoToJson(this);
}
