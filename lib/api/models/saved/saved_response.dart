import 'package:json_annotation/json_annotation.dart';

part 'saved_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SavedResponse {
  final String id;
  final int createdAt;

  SavedResponse({required this.id, required this.createdAt});

  factory SavedResponse.fromJson(Map<String, dynamic> json) =>
      _$SavedResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SavedResponseToJson(this);
}
