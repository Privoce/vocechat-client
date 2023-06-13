import 'package:json_annotation/json_annotation.dart';

part 'agora_config.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AgoraConfig {
  final bool enabled;
  final String? url;
  final String projectId;
  final String appId;
  final String appCertificate;
  final String customerId;
  final String customerSecret;

  AgoraConfig(
      {required this.enabled,
      this.url = "https://api.agora.io",
      required this.projectId,
      required this.appId,
      required this.appCertificate,
      required this.customerId,
      required this.customerSecret});

  factory AgoraConfig.fromJson(Map<String, dynamic> json) =>
      _$AgoraConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AgoraConfigToJson(this);
}
