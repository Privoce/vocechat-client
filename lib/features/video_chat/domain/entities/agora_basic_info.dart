import 'package:equatable/equatable.dart';

/// [AgoraBasicInfoEntity] holds the basic information required to join a channel
/// in Agora.
///
/// Entity should not be modified. All customizations should be done
/// in data layer.
///
/// Data returned from admin/agora/token API.
class AgoraBasicInfoEntity extends Equatable {
  final String agoraToken;
  final String appId;
  final int uid;
  final String channelName;
  final int expiredIn;

  const AgoraBasicInfoEntity(
      {required this.agoraToken,
      required this.appId,
      required this.uid,
      required this.channelName,
      required this.expiredIn});

  @override
  List<Object?> get props => [agoraToken, appId, uid, channelName, expiredIn];
}
