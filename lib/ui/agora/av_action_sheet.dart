import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/widgets/sheet_app_bar.dart';

class AvActionSheet extends StatefulWidget {
  final List<AvActionSheetItem> items;

  const AvActionSheet({Key? key, required this.items}) : super(key: key);

  @override
  State<AvActionSheet> createState() => _AvActionSheetState();
}

class _AvActionSheetState extends State<AvActionSheet> {
  final double _minHeight = 100;
  final double _maxHeight = 300;

  @override
  Widget build(BuildContext context) {
    final pageHeight = MediaQuery.of(context).size.height;
    final initialChildSize = _minHeight / pageHeight;
    final minChildSize = _minHeight / pageHeight;
    final maxChildSize = _maxHeight / pageHeight;

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16.0),
          ),
        ),
        child: Column(
          children: [
            SheetAppBar(),
            Flexible(
              child: Container(
                color: Colors.blue,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  controller: controller,
                  itemCount: 50,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AvActionSheetItem {
  final IconData icon;
  final VoidCallback onPressed;

  AvActionSheetItem({required this.icon, required this.onPressed});
}
