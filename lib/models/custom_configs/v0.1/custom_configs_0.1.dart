import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/models/custom_configs/v0.1/configs_0.1.dart';

part 'custom_configs_0.1.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CustomConfigs0001 {
  final String version;
  final Configs0001 configs;

  CustomConfigs0001({this.version = "0.1", required this.configs});

  bool get hasPreSetServerUrl => configs.serverUrl.isNotEmpty;

  factory CustomConfigs0001.fromJson(Map<String, dynamic> json) =>
      _$CustomConfigs0001FromJson(json);

  Map<String, dynamic> toJson() => _$CustomConfigs0001ToJson(this);
}
