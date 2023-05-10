import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BusyDialog extends StatefulWidget {
  const BusyDialog({Key? key, required this.busy}) : super(key: key);

  final ValueNotifier<bool> busy;

  @override
  _BusyDialogState createState() => _BusyDialogState();
}

class _BusyDialogState extends State<BusyDialog> {
  @override
  void initState() {
    super.initState();
    widget.busy.addListener(_handleBusyChanged);
  }

  @override
  void dispose() {
    widget.busy.removeListener(_handleBusyChanged);
    super.dispose();
  }

  void _handleBusyChanged() {
    if (widget.busy.value) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const CupertinoActivityIndicator(
            radius: 20,
          );
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
