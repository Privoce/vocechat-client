import 'package:json_annotation/json_annotation.dart';

part 'group_create_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GroupCreateResponse {
  final int gid;
  final int createdAt;

  GroupCreateResponse({required this.gid, required this.createdAt});

  factory GroupCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$GroupCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GroupCreateResponseToJson(this);
}
