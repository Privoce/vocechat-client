import 'package:json_annotation/json_annotation.dart';

part 'sys_org_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AdminSystemOrgInfo {
  final String name;
  final String? description;

  AdminSystemOrgInfo(this.name, this.description);

  factory AdminSystemOrgInfo.fromJson(Map<String, dynamic> json) =>
      _$AdminSystemOrgInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSystemOrgInfoToJson(this);
}
