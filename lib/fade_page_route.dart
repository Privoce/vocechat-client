import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRoute<T> {
  final Color? interBarrierColor;
  final Duration? duration;
  final Duration? reverseDuration;

  FadePageRoute(
      {required this.child,
      this.interBarrierColor,
      this.duration,
      this.reverseDuration});
  @override
  Color get barrierColor => interBarrierColor ?? Colors.transparent;

  @override
  String? get barrierLabel => null;

  final Widget child;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration ?? Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration =>
      reverseDuration ?? Duration(milliseconds: 300);
}
