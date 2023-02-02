import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';

class BannerTileGroup extends StatelessWidget {
  final String? title;
  final String? remark;
  final Divider? divider;
  final List<BannerTile> bannerTileList;
  final String? header;
  final String? footer;

  BannerTileGroup(
      {this.title,
      required this.bannerTileList,
      this.remark,
      this.divider,
      this.header,
      this.footer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null && header!.isNotEmpty)
          Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 4, right: 8),
              child: Text(header!,
                  style: TextStyle(
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w500,
                      fontSize: 14))),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                  horizontal: BorderSide(
                      color: CupertinoColors.systemGroupedBackground))),
          child: Column(
            children: List<Widget>.generate(bannerTileList.length, (index) {
              return Column(
                children: [
                  if (index != 0) divider ?? Divider(indent: 16),
                  bannerTileList[index]..showVerticalEdge = false
                ],
              );
            }),
          ),
        ),
        if (footer != null && footer!.isNotEmpty)
          Padding(
              padding: EdgeInsets.only(left: 16, top: 4, bottom: 8, right: 8),
              child: Text(footer!,
                  style: TextStyle(
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w400,
                      fontSize: 13))),
      ],
    );
  }
}
