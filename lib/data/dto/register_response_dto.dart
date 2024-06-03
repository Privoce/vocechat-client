import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/data/dto/user_info_dto.dart';

part 'register_response_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RegisterResponseDto {
  String? serverId;
  String? token;
  String? refreshToken;
  int? expiredIn;
  UserInfoDto? user;

  RegisterResponseDto({
    this.serverId,
    this.token,
    this.refreshToken,
    this.expiredIn,
    this.user,
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseDtoToJson(this);
}
