import 'package:flutter/material.dart';

class EmptyDataPlaceholder extends StatelessWidget {
  const EmptyDataPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text('No messages yet');
  }
}
