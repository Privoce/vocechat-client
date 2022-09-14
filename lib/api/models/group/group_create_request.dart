import 'package:json_annotation/json_annotation.dart';

part 'group_create_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GroupCreateRequest {
  final String name;
  final String description;
  final List<int>? members;
  final bool isPublic;

  GroupCreateRequest(
      {required this.name,
      required this.description,
      required this.isPublic,
      required this.members});

  factory GroupCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GroupCreateRequestToJson(this);
}
