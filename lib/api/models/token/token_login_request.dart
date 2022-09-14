import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/token/credential.dart';

part 'token_login_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TokenLoginRequest {
  final String device;
  final String deviceToken;
  final Credential credential;

  TokenLoginRequest(
      {required this.credential,
      this.device = "iPhone",
      this.deviceToken = ""});

  factory TokenLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$TokenLoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TokenLoginRequestToJson(this);
}
