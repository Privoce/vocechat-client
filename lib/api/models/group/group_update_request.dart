import 'package:json_annotation/json_annotation.dart';

part 'group_update_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GroupUpdateRequest {
  final String? name;
  final String? description;
  final int? owner;

  GroupUpdateRequest({this.name, this.description, this.owner});

  factory GroupUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GroupUpdateRequestToJson(this);
}
