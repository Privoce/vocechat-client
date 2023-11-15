import 'package:flutter/material.dart';

PageRouteBuilder gBottomUpRoute(
    Widget Function(BuildContext context, Animation<double>, Animation<double>)
        pageBuilder) {
  return PageRouteBuilder(
    pageBuilder: pageBuilder,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.fastOutSlowIn;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
