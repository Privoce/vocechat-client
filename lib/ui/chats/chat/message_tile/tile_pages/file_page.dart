import 'dart:io';
import 'dart:math';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/mixins/orientation_mixins.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:path/path.dart' as path;
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/tile_pages/pdf_page.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/tile_pages/video_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum FilePageStatus { download, open, share, downloading }

class FilePage extends StatefulWidget {
  final String filePath;

  /// This file name does not contain extension.
  final String fileName;
  final String extension;
  final int size;
  final Future<File?> Function() getLocalFile;
  final Future<File?> Function(Function(int, int)) getFile;
  final ChatMsgM? chatMsgM;

  FilePage(
      {required this.filePath,
      required this.fileName,
      required this.extension,
      required this.size,
      required this.getLocalFile,
      required this.getFile,
      this.chatMsgM});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  final ValueNotifier<double> _progress = ValueNotifier(0);
  final ValueNotifier<FilePageStatus> _status =
      ValueNotifier(FilePageStatus.download);
  File? _localFile;

  final ValueNotifier<bool> _enableShare = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    checkFileExist();
    // App.app.chatService.subscribeReaction(_onDelete);
  }

  @override
  void dispose() {
    // App.app.chatService.subscribeReaction(_onDelete);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.barBg,
        title: Text(
          AppLocalizations.of(context)!.file,
          style: AppTextStyles.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildFilePageBody(context)),
    );
  }

  Widget _buildFilePageBody(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildSvgPic(widget.extension),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                "${widget.fileName}.${widget.extension}",
                maxLines: 3,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                SharedFuncs.getFileSizeString(widget.size),
                style: AppTextStyles.labelMedium,
              ),
            ),
            ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 100, minHeight: 32)),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 48,
                width: double.maxFinite,
                child: ValueListenableBuilder<FilePageStatus>(
                    valueListenable: _status,
                    builder: (context, status, _) {
                      switch (status) {
                        case FilePageStatus.download:
                          return CupertinoButton.filled(
                              child:
                                  Text(AppLocalizations.of(context)!.download),
                              onPressed: () {
                                _download(widget.filePath, context);
                              });
                        case FilePageStatus.open:
                          return CupertinoButton.filled(
                              child: Text(AppLocalizations.of(context)!.open),
                              onPressed: () async {
                                _open(_localFile!);
                              });
                        case FilePageStatus.share:
                          return CupertinoButton.filled(
                              child: Text(AppLocalizations.of(context)!
                                  .openWithOtherApps),
                              onPressed: () async {
                                Share.shareXFiles([XFile(_localFile!.path)]);
                              });
                        case FilePageStatus.downloading:
                          return Center(
                            child: ValueListenableBuilder<double>(
                                valueListenable: _progress,
                                builder: ((context, value, child) {
                                  return LinearProgressIndicator(value: value);
                                })),
                          );
                        default:
                      }
                      return SizedBox.shrink();
                    }),
              ),
            ),
            Padding(
                padding: EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 48,
                  width: double.maxFinite,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _enableShare,
                    builder: (context, value, child) {
                      if (value) {
                        return CupertinoButton.filled(
                            child: Text(AppLocalizations.of(context)!.share),
                            onPressed: () async {
                              _shareFile(_localFile!,
                                  "${widget.fileName}.${widget.extension}");
                            });
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// To replace internal filename (localMid) with real name, making shared file
  /// consistant with the original one.
  void _shareFile(File file, String filename) async {
    final tempPath = "${(await getTemporaryDirectory()).path}/$filename";
    final tempFile = await file.copy(tempPath);
    Share.shareXFiles([XFile(tempFile.path)]);
  }

  void checkFileExist() async {
    _localFile = await widget.getLocalFile();

    if (_localFile == null) {
      _status.value = FilePageStatus.download;
      _enableShare.value = false;
    } else {
      _status.value = FilePageStatus.open;
      _enableShare.value = true;
    }
  }

  Future<void> _download(String filePath, BuildContext context) async {
    _status.value = FilePageStatus.downloading;
    await widget.getFile(
      (p0, p1) {
        final percentage = p0 / widget.size;
        _progress.value = percentage;
      },
    ).then((value) {
      if (value != null) {
        _localFile = value;
        _enableShare.value = true;
        _open(value);
      } else {
        showAppAlert(
            context: context,
            title: AppLocalizations.of(context)!.filePageCantFindFile,
            content: AppLocalizations.of(context)!.filePageCantFindFileContent,
            actions: [
              AppAlertDialogAction(
                  text: AppLocalizations.of(context)!.ok,
                  action: () => Navigator.of(context).pop())
            ]);
        _status.value = FilePageStatus.download;
        _enableShare.value = false;
      }
    }).onError((error, stackTrace) {
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.filePageDownloadFailed,
          content: AppLocalizations.of(context)!.filePageDownloadFailedContent,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () => Navigator.of(context).pop())
          ]);
      _status.value = FilePageStatus.download;
      _enableShare.value = false;
    });
  }

  void _open(File file) async {
    try {
      if (_isVideo(widget.extension)) {
        _status.value = FilePageStatus.open;
        _enableShare.value = true;
        final VideoPlayerController videoPlayerController =
            VideoPlayerController.file(file);
        await videoPlayerController.initialize();
        final ChewieController chewieController = ChewieController(
            videoPlayerController: videoPlayerController,
            autoPlay: false,
            looping: false);
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => VideoPage(chewieController)));
      } else if (widget.extension.toLowerCase() == "pdf") {
        _status.value = FilePageStatus.open;
        _enableShare.value = true;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PdfPage(widget.fileName, file)));
      } else {
        _status.value = FilePageStatus.share;
        _enableShare.value = false;
      }
    } catch (e) {
      App.logger.severe(e);
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.filePageCantOpenFile,
          content: AppLocalizations.of(context)!.filePageCantOpenFileContent,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () => Navigator.pop(context))
          ]);
    }
  }

  Widget _buildSvgPic(String extension) {
    Widget svgPic;
    double height = 72;
    double width = 54;
    if (_isAudio(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_audio.svg",
          width: width, height: height);
    } else if (_isVideo(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_video.svg",
          width: width, height: height);
    } else if (extension.toLowerCase() == "pdf") {
      svgPic = SvgPicture.asset("assets/images/file_pdf.svg",
          width: width, height: height);
    } else if (extension.toLowerCase() == "text") {
      svgPic = SvgPicture.asset("assets/images/file_txt.svg",
          width: width, height: height);
    } else if (_isImage(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_image.svg",
          width: width, height: height);
    } else if (_isCode(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_code.svg",
          width: width, height: height);
    } else {
      svgPic = SvgPicture.asset("assets/images/file.svg",
          width: width, height: height);
    }
    return svgPic;
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
}
