import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class InviteLinkView extends StatefulWidget {
  final int gid;

  InviteLinkView(this.gid);

  @override
  State<InviteLinkView> createState() => _InviteLinkViewState();
}

class _InviteLinkViewState extends State<InviteLinkView>
    with AutomaticKeepAliveClientMixin {
  late final Future<Response<String>> _linkFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final groupApi = GroupApi();
    _linkFuture = groupApi.createInviteLink(widget.gid);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.invitationLinkViewSend,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.grey600),
          ),
          SizedBox(height: 12),
          _buildLinkRelatedViews(),
        ],
      ),
    );
  }

  Widget _buildLinkRelatedViews() {
    return FutureBuilder<Response<String>>(
        future: _linkFuture,
        builder: (context, snapshot) {
          Widget content = Text("Unable to generate invite link.");
          bool enabled = false;
          String? url;

          if (snapshot.connectionState == ConnectionState.waiting) {
            enabled = false;
            url = null;

            content = Row(
              children: const [
                CupertinoActivityIndicator(),
                Text("Generating")
              ],
            );
          } else if (snapshot.hasData) {
            final res = snapshot.data;
            if (res != null && res.statusCode == 200) {
              enabled = true;
              url = res.data!;

              content = Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: AppColors.darkGrey),
              );
            }
          }

          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey100),
                      borderRadius: BorderRadius.circular(8)),
                  height: 42,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(child: content),
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  children: [
                    Text("Invite link expires in 7 days.  ",
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: AppColors.grey500)),
                    GestureDetector(
                      onTap: () {
                        setState(() {});
                      },
                      child: Text("Edit invite link.",
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: AppColors.primary400)),
                    )
                  ],
                ),
                Spacer(),
                _buildActions(enabled, url),
                SizedBox(height: 20)
              ],
            ),
          );
        });
  }

  Widget _buildActions(bool enabled, String? url) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
            onTap: () {
              if (enabled) Clipboard.setData(ClipboardData(text: url!));
            },
            child: Container(
                decoration: BoxDecoration(
                    color: enabled ? Colors.white : AppColors.grey200,
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 13),
                child: Center(
                    child: Text("Copy",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary400,
                        ))))),
        GestureDetector(
          onTap: () {
            if (enabled) Share.share(url!);
          },
          child: Container(
              decoration: BoxDecoration(
                  color: enabled ? AppColors.primary400 : AppColors.grey500,
                  borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 60, vertical: 13),
              child: Center(
                  child: Text("Share",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )))),
        )
      ],
    );
  }
}
