abstract class AvchatEvent {}

class AvchatInitRequest extends AvchatEvent {
  final bool isVideoCall;
  final int? uid;
  final int? gid;

  AvchatInitRequest({this.uid, this.gid, required this.isVideoCall}) {
    assert((uid != null) ^ (gid != null));
  }
}

class AvchatAvailabilityCheckRequest extends AvchatEvent {}

class AvchatTokenInfoRequest extends AvchatEvent {}

class AvchatPermissionCheckRequest extends AvchatEvent {}

class AvchatEngineInitRequest extends AvchatEvent {}

class AvchatJoinRequest extends AvchatEvent {}

class AvchatLeaveRequest extends AvchatEvent {}
