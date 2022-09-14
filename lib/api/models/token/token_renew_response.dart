import 'package:json_annotation/json_annotation.dart';

part 'token_renew_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TokenRenewResponse {
  final String token;
  final String refreshToken;
  final int expiredIn;

  TokenRenewResponse(this.token, this.refreshToken, this.expiredIn);

  factory TokenRenewResponse.fromJson(Map<String, dynamic> json) => _$TokenRenewResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenRenewResponseToJson(this);
}
