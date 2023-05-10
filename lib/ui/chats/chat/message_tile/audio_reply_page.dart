// import 'dart:io';

// import 'package:audio_waveforms/audio_waveforms.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:vocechat_client/app.dart';
// import 'package:vocechat_client/app_consts.dart';
// import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
// import 'package:vocechat_client/services/audio_service.dart';
// import 'package:vocechat_client/ui/app_colors.dart';
// import 'package:vocechat_client/ui/chats/chat/message_tile/audio_bubble.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// class AudioReplyPage extends StatefulWidget {
//   const AudioReplyPage({
//     Key? key,
//     required this.audioInfo,
//   }) : super(key: key);

//   final AudioInfoState audioInfo;

//   @override
//   State<AudioReplyPage> createState() => _AudioReplyPageState();
// }

// class _AudioReplyPageState extends State<AudioReplyPage> {
//   final _buttonSize = 48.0;

//   final _waveformHorizontalPadding = 8.0;

//   final controller = PlayerController();

//   @override
//   void dispose() {
//     AudioService().remove("${widget.audioInfo.localMid}_new");
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         toolbarHeight: barHeight,
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         leading: CupertinoButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
//       ),
//       body: SafeArea(
//           child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: FutureBuilder<AudioInfoState?>(
//             future: _prepareNewAudioInfoState(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.done) {
//                 if (snapshot.hasData) {
//                   final newAudioInfo = snapshot.data!;
//                   return AudioBubble(
//                       audioInfo: newAudioInfo,
//                       width: MediaQuery.of(context).size.width -
//                           _buttonSize * 2 -
//                           _waveformHorizontalPadding * 2);
//                 } else {
//                   return Text(
//                       AppLocalizations.of(context)!.messageHasBeenDeleted);
//                 }
//               } else {
//                 return const CupertinoActivityIndicator();
//               }
//             },
//           ),
//         ),
//       )),
//     );
//   }

//   Future<AudioInfoState?> _prepareNewAudioInfoState() async {
//     try {
//       final chatMsgM =
//           await ChatMsgDao().getMsgBylocalMid(widget.audioInfo.localMid);
//       final file = File(widget.audioInfo.audioPath);

//       if (chatMsgM != null && await file.exists()) {
//         return AudioInfoState.getAudioInfo(chatMsgM, file: file, isNew: true);
//       }
//     } catch (e) {
//       App.logger.severe(e);
//     }

//     return null;
//   }
// }
