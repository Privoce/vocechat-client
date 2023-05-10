import 'dart:async';

import 'package:flutter/material.dart';

class AlternatingWidget extends StatefulWidget {
  /// The children to alternate between.
  ///
  /// Must be the same length as the [durations] list.
  final List<Widget> children;

  /// The durations for each child.
  ///
  /// Must be the same length as the [children] list.
  final List<Duration>? durations;

  /// The default duration to use when the [durations] list is empty.
  final Duration? defaultDuration;

  /// Creates a widget that alternates between the given children.
  ///
  /// The children are displayed in the order they are given. The durations
  /// determine how long each child is displayed before the next one is shown.
  /// The number of items in the [durations] list must be equal to the number
  /// of items in the [children] list.
  AlternatingWidget(
      {required this.children, this.durations, this.defaultDuration});

  @override
  State<AlternatingWidget> createState() => _AlternatingWidgetState();
}

class _AlternatingWidgetState extends State<AlternatingWidget> {
  /// The index of the current child.
  int currentIndex = 0;

  @override
  initState() {
    super.initState();
    currentIndex = 0;
    _start();
  }

  /// Starts the alternating timer.
  void _start() {
    if (widget.defaultDuration != null &&
        (widget.durations == null || widget.durations!.isEmpty)) {
      Timer.periodic(widget.defaultDuration!, (timer) {
        _incrementCounter();
      });
    } else {
      Timer.periodic(widget.defaultDuration!, (timer) {
        _incrementCounter();
      });
    }
  }

  /// Increments the counter and resets it if it is out of bounds.
  void _incrementCounter() {
    if (mounted) {
      setState(() {
        currentIndex++;
        if (currentIndex >= widget.children.length) {
          currentIndex = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.children[currentIndex];
  }
}
