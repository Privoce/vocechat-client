import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_bloc.dart';
import 'package:vocechat_client/feature/avchat/presentation/bloc/avchat_states.dart';

class AvchatStatusText extends StatefulWidget {
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
          statusText = "Agora Initialized";
          break;
        case AgoraInitFail:
          statusText = "Agora Init Fail";
          break;
        case AgoraJoiningChannel:
          statusText = "Agora Joining";
          break;
        case AgoraChannelJoined:
          statusText = "Agora Joined";
          break;
        case AgoraJoinFail:
          statusText = "Agora Join Fail";
          break;
        case AgoraCallOnGoing:
          final seconds = (state as AgoraCallOnGoing).seconds;
          statusText = _formatTime(seconds);
          break;
        case AgoraLeftChannel:
          statusText = "Agora Left";
          break;
        case AgoraLeaveFail:
          statusText = "Agora Leave Fail";
          break;
        default:
          statusText = "";
      }
      return Text(statusText);
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
