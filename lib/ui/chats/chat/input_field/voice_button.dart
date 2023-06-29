import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/file_handler/audio_file_handler.dart';
import 'package:vocechat_client/services/voce_send_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';

enum VoiceButtonType { recording, cancelling, normal }

class VoiceButton extends StatefulWidget {
  // final GlobalKey<NavigatorState> deleteButtonKey;
  final ValueNotifier<VoiceButtonType> voiceButtonTypeNotifier;
  // final String chatId;
  final int? uid;
  final int? gid;

  VoiceButton({required this.voiceButtonTypeNotifier, this.uid, this.gid});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  late final ValueNotifier<VoiceButtonType> _voiceButtonType;
  VoiceButtonType? _previousVoiceButtonType;
  late Offset? deleteButtonOffset;

  late String chatId;

  /// The distance threshold for canceling the recording.
  ///
  /// When the user drags the button within [cancelThresholdLeft] and
  /// [cancelThresholdTop],
  /// the recording will be cancelled.
  final double cancelThresholdLeft = 88;

  ValueNotifier<int> recordDuration = ValueNotifier(0);
  Timer? _timer;
  final record = Record();

  AudioFilePathInfo? _audioFilePathInfo;

  bool get isChannel => widget.gid != null;
  bool get isUser => widget.uid != null;

  @override
  void initState() {
    super.initState();
    chatId = SharedFuncs.getChatId(uid: widget.uid, gid: widget.gid) ?? "";

    _voiceButtonType = widget.voiceButtonTypeNotifier;

    _voiceButtonType.addListener(() {
      switch (_voiceButtonType.value) {
        case VoiceButtonType.recording:
          _startsRecording();
          break;
        case VoiceButtonType.normal:
          _stopsRecording();
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        updateVoiceButtonType(VoiceButtonType.recording);
      },
      onPanCancel: () {
        updateVoiceButtonType(VoiceButtonType.normal);
      },
      onPanEnd: (details) {
        updateVoiceButtonType(VoiceButtonType.normal);
      },
      onPanUpdate: (details) {
        if (details.globalPosition.dx < cancelThresholdLeft) {
          updateVoiceButtonType(VoiceButtonType.cancelling);
        } else {
          updateVoiceButtonType(VoiceButtonType.recording);
        }
      },
      child: ValueListenableBuilder<VoiceButtonType>(
          valueListenable: _voiceButtonType,
          builder: (context, type, _) {
            switch (type) {
              case VoiceButtonType.normal:
                return Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                        child: Text(AppLocalizations.of(context)!.holdAndSpeak,
                            style: const TextStyle(fontSize: 16))));

              case VoiceButtonType.cancelling:
                return Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ValueListenableBuilder<int>(
                                valueListenable: recordDuration,
                                builder: (context, seconds, _) {
                                  Duration duration =
                                      Duration(seconds: seconds);
                                  String mmss =
                                      "${duration.inMinutes.remainder(60)}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}";
                                  return Text(mmss,
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ));
                                }),
                          ),
                          Expanded(
                            child: Text(
                                AppLocalizations.of(context)!.releaseToCancel,
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          )
                        ],
                      ),
                    )));
              case VoiceButtonType.recording:
                return Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ValueListenableBuilder<int>(
                                valueListenable: recordDuration,
                                builder: (context, seconds, _) {
                                  Duration duration =
                                      Duration(seconds: seconds);
                                  String mmss =
                                      "${duration.inMinutes.remainder(60)}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}";
                                  return Text(mmss,
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ));
                                }),
                          ),
                          const Spacer(),
                          Text(AppLocalizations.of(context)!.releaseToSend,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    )));
              default:
            }

            return Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                    child: Text(AppLocalizations.of(context)!.holdAndSpeak,
                        style: const TextStyle(fontSize: 16))));
          }),
    );
  }

  void updateVoiceButtonType(VoiceButtonType type) {
    _previousVoiceButtonType = _voiceButtonType.value;
    _voiceButtonType.value = type;
  }

  /// Starts the recording
  ///
  /// This method will check if the user has granted the microphone permission.
  /// If not, it will ask for it.
  void _startsRecording() async {
    if (_timer != null && _timer!.isActive) return;

    if (await record.hasPermission()) {
      final audioPathInfo = await _generateAudioPathInfo();
      final path = await audioPathInfo.filePath;

      // Must be called before start to ensure recording is saved.
      await File(path).create(recursive: true);

      await record.start(
          path: path,
          encoder: AudioEncoder.aacLc,
          bitRate: 16000,
          samplingRate: 8000);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        recordDuration.value++;
      });
    } else {
      _showNoPermissionWarning();
    }
  }

  void _stopsRecording() async {
    final path = await record.stop();
    _timer?.cancel();

    if (_previousVoiceButtonType == VoiceButtonType.cancelling ||
        (_previousVoiceButtonType == VoiceButtonType.recording &&
            recordDuration.value < 1)) {
      if (_audioFilePathInfo != null) {
        await AudioFileHandler().delete(_audioFilePathInfo!.fileName,
            chatId: _audioFilePathInfo!.chatId);
      }
      return;
    } else if (_previousVoiceButtonType == VoiceButtonType.recording) {
      final audioFile = File(path ?? "");
      if (await audioFile.exists() && _audioFilePathInfo != null) {
        final localMid = _audioFilePathInfo!.uuid;
        if (isChannel) {
          VoceSendService().sendChannelAudio(widget.gid!, localMid, audioFile);
        } else if (isUser) {
          VoceSendService().sendUserAudio(widget.uid!, localMid, audioFile);
        }
      }
    }
    recordDuration.value = 0;
  }

  Future<AudioFilePathInfo> _generateAudioPathInfo() async {
    final uuidStr = uuid();
    _audioFilePathInfo = AudioFilePathInfo(chatId: chatId, uuid: uuidStr);

    return _audioFilePathInfo!;
  }

  /// Show a warning dialog when the user has denied the microphone permission
  ///
  /// This dialog will show a message and a button to open the app settings
  void _showNoPermissionWarning() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.microphonePermissionRequired,
          content:
              AppLocalizations.of(context)!.microphonePermissionRequiredDes,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.goToSettings,
                action: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                }),
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.cancel,
                action: () => Navigator.of(context).pop()),
          ]);
    }
  }
}

class AudioFilePathInfo {
  final String uuid;
  final String chatId;

  String get fileName => AudioFileHandler.generateFileName(uuid);

  Future<String> get filePath async =>
      await AudioFileHandler().filePath(fileName, chatId: chatId);

  AudioFilePathInfo({required this.uuid, required this.chatId});
}
