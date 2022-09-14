import 'package:json_annotation/json_annotation.dart';

part 'file_prepare_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class FilePrepareRequest {
  final String contentType;
  final String filename;

  FilePrepareRequest({required this.contentType, required this.filename});

  factory FilePrepareRequest.fromJson(Map<String, dynamic> json) =>
      _$FilePrepareRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FilePrepareRequestToJson(this);
}
