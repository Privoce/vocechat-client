import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/widgets/sheet_app_bar.dart';

class AvActionSheet extends StatefulWidget {
  final List<Widget> btnItems;
  final List<Widget>? listItems;

  const AvActionSheet({Key? key, required this.btnItems, this.listItems})
      : super(key: key);

  @override
  State<AvActionSheet> createState() => _AvActionSheetState();
}

class _AvActionSheetState extends State<AvActionSheet> {
  final double _dragBarHeight = 16;
  final double _actionBtnBarTopPadding = 8;
  final double _actionBtnBarBottomPadding = 8;
  final double _actionBtnHeight = 56; // 24 + 16 * 2

  final DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pageHeight = MediaQuery.of(context).size.height;
    final bottomOffset = MediaQuery.of(context).padding.bottom;

    final maxHeight = pageHeight * 0.6;
    final minHeight = _dragBarHeight +
        _actionBtnBarTopPadding +
        _actionBtnBarBottomPadding +
        _actionBtnHeight +
        bottomOffset;
    final initialChildSize = minHeight / pageHeight;
    final minChildSize = minHeight / pageHeight;
    final maxChildSize = maxHeight / pageHeight;

    return DraggableScrollableSheet(
      // controller: draggableScrollableController,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: true,
      snapSizes: [minChildSize, maxChildSize],
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_dragBarHeight),
          ),
        ),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(top: _dragBarHeight),
              controller: controller,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: _actionBtnBarTopPadding,
                      bottom: _actionBtnBarBottomPadding,
                      left: 16,
                      right: 16),
                  child: _buildActions(context),
                ),
                ..._prepareList()
              ],
            ),
            IgnorePointer(
                ignoring: false,
                child: SizedBox(
                    width: double.maxFinite,
                    height: _dragBarHeight,
                    child: Column(
                      children: [
                        SheetAppBar(),
                      ],
                    ))),
          ],
        ),
      ),
    );
  }

  List<Widget> _prepareList() {
    if (widget.listItems == null) return List.empty();

    return widget.listItems!;
  }

  Widget _buildActions(
    BuildContext context,
  ) {
    const double minGap = 16.0;
    const double buttonIconSize = 24;
    const double buttonSize = 56; // 24 + 16*2

    return LayoutBuilder(builder: (context, constrain) {
      final itemCount = widget.btnItems.length;

      // without left and right padding
      final minWidth = buttonSize * itemCount + minGap * (itemCount - 1);

      if (minWidth > constrain.maxWidth) {
        return SizedBox(
          height: buttonIconSize,
          width: double.maxFinite,
          child: ListView(
              scrollDirection: Axis.horizontal,
              children: List<Widget>.generate(itemCount, (index) {
                if (index != itemCount - 1) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // RoundButton(
                      //     icon: widget.btnItems[index].icon,
                      //     size: buttonIconSize,
                      //     onPressed: widget.btnItems[index].onPressed),
                      widget.btnItems[index],
                      SizedBox(width: minGap)
                    ],
                  );
                } else {
                  // return RoundButton(
                  //     icon: widget.btnItems[index].icon,
                  //     size: buttonIconSize,
                  //     onPressed: widget.btnItems[index].onPressed);
                  return widget.btnItems[index];
                }
              })),
        );
      } else {
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.btnItems);
      }
    });
  }
}

class AvActionSheetBtnItem {
  final IconData icon;
  final VoidCallback onPressed;

  AvActionSheetBtnItem({required this.icon, required this.onPressed});
}

class AvActionSheetListItem {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  AvActionSheetListItem(
      {required this.icon, required this.title, required this.onPressed});
}
