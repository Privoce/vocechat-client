import 'package:json_annotation/json_annotation.dart';

part 'file_upload_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class FileUploadResponse {
  final String path;
  final int size;
  final String hash;
  final Map<String, dynamic>? imageProperties;

  FileUploadResponse(
      {required this.path,
      required this.size,
      required this.hash,
      required this.imageProperties});

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$FileUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FileUploadResponseToJson(this);
}
