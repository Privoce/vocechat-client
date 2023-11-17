import 'package:equatable/equatable.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';

enum AvchatUserConnectionState {
  disconnected,
  connecting,
  connected,
}

class AvchatUser extends Equatable {
  final UserInfoM userInfoM;
  final AvchatUserConnectionState state;
  final bool muted;

  const AvchatUser(
      {required this.userInfoM, required this.state, required this.muted});

  AvchatUser copyWith({UserInfoM? userInfoM, bool? muted}) {
    return AvchatUser(
        userInfoM: userInfoM ?? this.userInfoM,
        state: state,
        muted: muted ?? this.muted);
  }

  @override
  List<Object?> get props => [userInfoM, muted];
}
