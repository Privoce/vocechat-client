import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/admin/login/login_config.dart';
import 'package:vocechat_client/api/models/admin/system/sys_common_info.dart';

part 'chat_server_properties.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ChatServerProperties {
  String serverName;
  String? description;
  AdminLoginConfig? config;
  AdminSystemCommonInfo? commonInfo;

  ChatServerProperties(
      {this.serverName = "server",
      this.description,
      this.config,
      this.commonInfo});

  factory ChatServerProperties.fromJson(Map<String, dynamic> json) =>
      _$ChatServerPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$ChatServerPropertiesToJson(this);
}
