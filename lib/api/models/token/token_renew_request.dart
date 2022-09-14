import 'package:json_annotation/json_annotation.dart';

part 'token_renew_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TokenRenewRequest {
  final String token;
  final String refreshToken;

  TokenRenewRequest(this.token, this.refreshToken);

  factory TokenRenewRequest.fromJson(Map<String, dynamic> json) => _$TokenRenewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TokenRenewRequestToJson(this);
}
