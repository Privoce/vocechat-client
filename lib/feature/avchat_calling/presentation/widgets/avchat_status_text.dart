import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/feature/avchat_calling/presentation/bloc/avchat_bloc.dart';

class AvchatStatusText extends StatefulWidget {
  final TextStyle? style;

  const AvchatStatusText({super.key, this.style});

  @override
  State<AvchatStatusText> createState() => _AvchatStatusTextState();
}

class _AvchatStatusTextState extends State<AvchatStatusText> {
  @override
  Widget build(BuildContext context) {
    String statusText = "";
    return BlocBuilder<AvchatBloc, AvchatState>(builder: (context, state) {
      switch (state.runtimeType) {
        case CheckingAvchatAvailability:
          statusText = "Checking Avchat Availability";
          break;
        case AvchatAvailable:
          statusText = "Avchat Available";
          break;
        case AvchatUnavailable:
          statusText = "Avchat not available";
          break;
        case AvchatAvailabilityCheckFail:
          statusText = "Avchat Availability Check Fail";
          break;
        case AvchatPermissionEnabled:
          break;
        case AvchatPermissionDisabled:
          final permissionState = state as AvchatPermissionDisabled;
          statusText =
              "Avchat Permission Disabled, ${permissionState.isMicPermissionRequired ? "Mic" : ""} ${permissionState.isCameraPermissionRequired ? "Camera" : ""} Permission Required}";
          break;
        case AvchatPermissionCheckFail:
          statusText = "Avchat Permission Check Fail";
          break;
        case AvchatTokenInfoReceived:
          statusText = "Avchat Token Info Received";
          break;
        case AvchatTokenInfoFail:
          statusText = "Avchat Token Info Fail";
          break;
        case AgoraInitializing:
          statusText = "Agora Initializing";
          break;
        case AgoraInitialized:
          statusText = " Initialized";
          break;
        case AgoraInitFail:
          statusText = " Init Fail";
          break;
        case AgoraJoiningChannel:
          statusText = " Joining";
          break;
        case AgoraSelfJoined:
          statusText = " Joined";
          break;
        case AgoraSelfJoinFail:
          statusText = " Join Fail";
          break;
        case AgoraCallOnGoing:
          final seconds = (state as AgoraCallOnGoing).seconds;
          statusText = _formatTime(seconds);
          break;
        case AgoraWaitingForPeer:
          statusText = " Waiting For Peer";
          break;
        case AgoraGuestJoined:
          final uid = (state as AgoraGuestJoined).userInfoM.uid;
          statusText = " Guest Joined, uid: $uid";
          break;
        case AgoraGuestLeft:
          final uid = (state as AgoraGuestLeft).userInfoM.uid;
          statusText = " Guest Left, uid: $uid";
          break;
        case AgoraLeftChannel:
          statusText = " Left";
          break;
        case AgoraLeaveFail:
          statusText = " Leave Fail";
          break;
        case AvchatConnectionStateChanged:
          final connectionState = state as AvchatConnectionStateChanged;
          statusText =
              "Connection State Changed, uid: ${connectionState.uid}, state: ${connectionState.state}, reason: ${connectionState.reason}";
          break;
        default:
        // statusText = "";
      }
      return Text(statusText,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: widget.style ??
              TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()]));
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secondsLeft = seconds % 60;

    String formattedMinutes = minutes.toString().padLeft(2, '0');
    String formattedSeconds = secondsLeft.toString().padLeft(2, '0');

    return "$formattedMinutes:$formattedSeconds";
  }
}
