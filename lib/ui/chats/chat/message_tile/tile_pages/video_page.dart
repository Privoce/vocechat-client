import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VideoPage extends StatefulWidget {
  final ChewieController chewieController;
  final File file;

  const VideoPage(this.chewieController, this.file, {super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
// with PortraitStatefulModeMixin<VideoPage>
{
  final saveToAlbumStatus = ValueNotifier<ButtonStatus>(ButtonStatus.normal);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.chewieController.pause();
    widget.chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
        centerTitle: true,
      ),
      body: widget.chewieController.videoPlayerController.value.isInitialized
          ? SafeArea(child: Chewie(controller: widget.chewieController))
          : Center(child: CupertinoActivityIndicator()),
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _saveToAlbumButton(context),
            CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  try {
                    Share.shareXFiles([XFile(widget.file.path)]);
                  } catch (e) {
                    App.logger.severe(e);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.share, color: AppColors.grey97),
                    Flexible(
                      child: Text(AppLocalizations.of(context)!.share,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: AppColors.grey97, fontSize: 14)),
                    )
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _saveToAlbumButton(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () async {
          try {
            showSnackBar(ButtonStatus.inProgress);
            await SaverGallery.saveFile(
                    file: widget.file.path,
                    name: widget.file.path.split("/").last,
                    androidExistNotSave: false)
                .then((value) {
              if (value.isSuccess) {
                showSnackBar(ButtonStatus.success);
              } else {
                showSnackBar(ButtonStatus.error);
              }
            });
          } catch (e) {
            App.logger.severe(e);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.arrow_down_to_line_alt,
                color: AppColors.grey97),
            Flexible(
              child: Text(AppLocalizations.of(context)!.saveToAlbum,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.grey97, fontSize: 14)),
            )
          ],
        ));
  }

  void showSnackBar(ButtonStatus status) {
    String snackText;

    switch (status) {
      case ButtonStatus.success:
        snackText = AppLocalizations.of(context)!.savedSuccessfully;
        break;
      case ButtonStatus.error:
        snackText = AppLocalizations.of(context)!.saveFailed;
        break;
      case ButtonStatus.inProgress:
        snackText = AppLocalizations.of(context)!.saving;
        break;
      default:
        snackText = AppLocalizations.of(context)!.saveToAlbum;
    }

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackText), duration: Duration(seconds: 1)));
  }
}
