// TODO: this class should do :
// 1. has initial image file, high-res by default, else use thumb
// 2. has a getter of original image download method
import 'dart:io';

import 'package:vocechat_client/dao/init_dao/chat_msg.dart';

class SingleImageItem {
  final File initImageFile;
  final ChatMsgM chatMsgM;

  // TODO: change logic of this function to:
  // if there is local high-res, load local high-res;
  // else if there is local thumb, load it;
  //   then show high-res button to load high-res from server.
  //     if no high-res on server, show warnings and continue display thumb.
  // else if there is no local thumb, load from server
  // else if there is no server image, show warning.
  // final Future<File?>? Function(
  //         Function(int progress, int size)? progressIndicator)?
  //     loadOriginalImageFileCallBack;

  Future<File?>? Function(Function(int progress, int size)? progressIndicator)?
      get loadOriginalImageFileCallBack {
    // final String localMid =
  }

  SingleImageItem({required this.initImageFile, required this.chatMsgM});
}
