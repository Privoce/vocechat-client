import 'package:json_annotation/json_annotation.dart';

part 'contact_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ContactInfo {
  final String status;
  final int createdAt;
  final int updatedAt;

  ContactInfo(
      {required this.status, required this.createdAt, required this.updatedAt});

  factory ContactInfo.fromJson(Map<String, dynamic> json) =>
      _$ContactInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ContactInfoToJson(this);
}
