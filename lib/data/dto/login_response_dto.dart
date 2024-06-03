import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/data/dto/user_info_dto.dart';

part 'login_response_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class LoginResponseDto {
  @JsonKey(name: 'server_id')
  String? serverId;
  String? token;
  String? refreshToken;
  int? expiredIn;
  UserInfoDto? user;

  LoginResponseDto({
    this.serverId,
    this.token,
    this.refreshToken,
    this.expiredIn,
    this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseDtoToJson(this);
}
