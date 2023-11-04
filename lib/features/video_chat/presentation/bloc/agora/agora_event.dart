abstract class AgoraEvent {
  const AgoraEvent();
}

class AgoraInitialize extends AgoraEvent {
  const AgoraInitialize();
}

class AgoraJoinChannel extends AgoraEvent {
  const AgoraJoinChannel();
}

class AgoraLeaveChannel extends AgoraEvent {
  const AgoraLeaveChannel();
}

// class AgoraMute extends AgoraEvent {
//   bool toMute;
//   const AgoraMute();
// }

// mute 

