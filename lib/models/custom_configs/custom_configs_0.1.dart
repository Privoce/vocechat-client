import 'package:json_annotation/json_annotation.dart';

part 'custom_configs_0.1.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CustomConfigs0001 {
  final String version;
  final String serverUrl;

  CustomConfigs0001({this.version = "0.1", required this.serverUrl});

  factory CustomConfigs0001.fromJson(Map<String, dynamic> json) =>
      _$CustomConfigs0001FromJson(json);

  Map<String, dynamic> toJson() => _$CustomConfigs0001ToJson(this);
}
