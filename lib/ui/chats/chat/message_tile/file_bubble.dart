import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/tile_pages/file_page.dart';

import 'package:path/path.dart' as p;

class FileBubble extends StatelessWidget {
  final String filePath;
  final String name;

  /// Integer size in byte.
  final int size;
  final Future<File?> Function() getLocalFile;
  final Future<File?> Function(Function(int, int)) getFile;
  final ChatMsgM? chatMsgM;

  FileBubble(
      {required this.filePath,
      required this.name,
      required this.size,
      required this.getLocalFile,
      required this.getFile,
      this.chatMsgM});

  @override
  Widget build(BuildContext context) {
    if (filePath.isEmpty || name.isEmpty) {
      return SizedBox.shrink();
    }

    final filename = p.basenameWithoutExtension(name);
    String extension;
    try {
      extension = p.extension(name).substring(1);
    } catch (e) {
      App.logger.severe(e);
      extension = "";
    }

    Widget svgPic;

    if (_isAudio(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_audio.svg",
          width: 36, height: 48);
    } else if (_isVideo(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_video.svg",
          width: 36, height: 48);
    } else if (extension.toLowerCase() == "pdf") {
      svgPic =
          SvgPicture.asset("assets/images/file_pdf.svg", width: 36, height: 48);
    } else if (extension.toLowerCase() == "txt") {
      svgPic =
          SvgPicture.asset("assets/images/file_txt.svg", width: 36, height: 48);
    } else if (_isImage(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_image.svg",
          width: 36, height: 48);
    } else if (_isCode(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_code.svg",
          width: 36, height: 48);
    } else {
      svgPic =
          SvgPicture.asset("assets/images/file.svg", width: 36, height: 48);
    }

    return GestureDetector(
      onTap: () => _viewFile(context),
      child:
          // _isVideo(extension)
          //     ? bubble
          //     :
          Container(
        decoration: BoxDecoration(
            border: Border.all(color: Color.fromRGBO(212, 212, 212, 1)),
            borderRadius: BorderRadius.circular(6),
            color: Color.fromRGBO(243, 244, 246, 1)),
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            svgPic,
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          filename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Color.fromRGBO(28, 28, 30, 1),
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        "." + extension,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Color.fromRGBO(28, 28, 30, 1),
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(getFileSizeString(size),
                      style: TextStyle(
                          color: Color.fromRGBO(97, 97, 97, 1),
                          fontSize: 12,
                          fontWeight: FontWeight.w400))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getFileSizeString(int bytes) {
    const suffixes = ["b", "kb", "mb", "gb", "tb"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) +
        suffixes[i].toUpperCase();
  }

  bool _isAudio(String extension) {
    return audioExts.contains(extension.toLowerCase());
  }

  bool _isVideo(String extension) {
    return videoExts.contains(extension.toLowerCase());
  }

  bool _isImage(String extension) {
    return imageExts.contains(extension.toLowerCase());
  }

  bool _isCode(String extension) {
    return codeExts.contains(extension.toLowerCase());
  }

  bool fileExists(String filePath) => File(filePath).existsSync();

  Future setFilePath(String type, String assetPath) async {
    final _directory = await getTemporaryDirectory();
    return "${_directory.path}/fileview/${base64.encode(utf8.encode(assetPath))}.$type";
  }

  // Future onNetworkTap(BuildContext context, String title, String type,
  //     String downloadUrl) async {
  //   String filePath = await setFilePath(type, title);
  //   if (fileExists(filePath)) {
  //     Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
  //       return LocalFileViewerPage(filePath: filePath);
  //     }));
  //   } else {
  //     Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
  //       return NetworkFileViewerPage(
  //         downloadUrl: downloadUrl,
  //         downloadPath: filePath,
  //       );
  //     }));
  //   }
  // }
  // Future onNetworkTap(BuildContext context, String fileName, String extension,
  //     String path) async {
  //   Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
  //     return PDFBubble(
  //       url: path,
  //     );
  //   }));
  // }

  Future<void> _viewFile(BuildContext context) async {
    final fileName = p.basenameWithoutExtension(name);
    final extension = p.extension(name).split(".").last;

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => FilePage(
            filePath: filePath,
            fileName: fileName,
            extension: extension,
            size: size,
            getLocalFile: getLocalFile,
            getFile: getFile,
            chatMsgM: chatMsgM)));
  }
}
