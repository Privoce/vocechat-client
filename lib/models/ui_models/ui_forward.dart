import 'dart:typed_data';

class UiForward {
  final Uint8List? avatar;
  final String title;
  final int? memberCount;
  final int? uid;
  final int? gid;
  final int time;

  late final bool isGroup;
  final bool isPublicChannel;

  UiForward(
      {this.avatar,
      required this.title,
      this.memberCount,
      this.uid,
      this.gid,
      required this.time,
      this.isPublicChannel = false}) {
    if (gid != null) {
      isGroup = true;
    } else {
      isGroup = false;
    }
  }
}
