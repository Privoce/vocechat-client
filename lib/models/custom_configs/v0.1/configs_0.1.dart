import 'package:json_annotation/json_annotation.dart';

part 'configs_0.1.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Configs0001 {
  final String serverUrl;

  Configs0001({required this.serverUrl});

  factory Configs0001.fromJson(Map<String, dynamic> json) =>
      _$Configs0001FromJson(json);

  Map<String, dynamic> toJson() => _$Configs0001ToJson(this);
}
