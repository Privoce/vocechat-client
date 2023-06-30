import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class InviteBarBottom extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Tab> tabs;

  InviteBarBottom({required this.controller, required this.tabs});

  @override
  Size get preferredSize => Size(double.maxFinite, 40);

  @override
  Widget build(BuildContext context) {
    return TabBar(
        labelColor: AppColors.primary500,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelColor: AppColors.grey600,
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        controller: controller,
        tabs: tabs);
  }
}
