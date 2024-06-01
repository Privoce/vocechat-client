import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/data/dto/login_credential_dto.dart';

part 'login_request_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class LoginRequestDto {
  final LoginCredentialDto? credential;

  /// Used to distinguish the device that is used to login.
  /// Multiple login sessions with same [device] is not allowed.
  final String? device;

  /// Used to send push notification to the device.
  /// Currently using FCM.
  final String? deviceToken;

  LoginRequestDto({
    this.credential,
    this.device,
    this.deviceToken,
  });

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);
}
