import 'package:json_annotation/json_annotation.dart';

part 'server_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ServerInfo {
  String name;
  String? description;

  /// url or ip address, without port num.
  String url;

  ServerInfo({
    required this.name,
    this.description,
    required this.url,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ServerInfoToJson(this);
}
