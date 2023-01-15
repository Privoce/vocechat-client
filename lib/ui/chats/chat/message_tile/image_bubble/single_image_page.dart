import 'dart:io';
import 'package:flutter/material.dart';

class SingleImagePage extends StatefulWidget {
  final File initImageFile;
  final Future<File?>? Function(
          Function(int progress, int size)? progressIndicator)?
      loadOriginalImageFileCallBack;

  final int? originalImageSize;

  const SingleImagePage(
      {Key? key,
      required this.initImageFile,
      required this.loadOriginalImageFileCallBack,
      this.originalImageSize})
      : super(key: key);

  @override
  State<SingleImagePage> createState() => _SingleImagePageState();
}

class _SingleImagePageState extends State<SingleImagePage>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<File> _imageNotifier;
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0);

  // For zoom in and out.
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails _doubleTapDetails = TapDownDetails();
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  final _zoomInMaxScale = 3.0;
  final _zoomDuration = const Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _initImageNotifier();
    _initAnimationController();

    _loadOriginalImageFile();
  }

  void _initImageNotifier() {
    _imageNotifier = ValueNotifier(widget.initImageFile);
  }

  void _initAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: _zoomDuration,
    )..addListener(() {
        _transformationController.value = _animation.value;
      });
  }

  Future<void> _loadOriginalImageFile() async {
    if (widget.loadOriginalImageFileCallBack != null) {
      final originalImageFile =
          await widget.loadOriginalImageFileCallBack!(((progress, size) {
        print("progress: $progress, size: $size");
        _progressNotifier.value = progress / size;
      }));

      if (originalImageFile != null) {
        _progressNotifier.value = 1;
        _imageNotifier.value = originalImageFile;
      }
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    Matrix4 endMatrix;
    Offset position = _doubleTapDetails.localPosition;

    if (_transformationController.value != Matrix4.identity()) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(_zoomInMaxScale);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurveTween(curve: Curves.decelerate).animate(_animationController),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final child = ValueListenableBuilder<File>(
        valueListenable: _imageNotifier,
        builder: (context, imageFile, _) {
          return Stack(
            children: [
              Center(
                  child: Image.file(
                imageFile,
                fit: BoxFit.fitWidth,
                height: double.infinity,
                width: double.infinity,
                alignment: Alignment.center,
              )),
              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, value, child) {
                  if (value < 0.05 || value >= 1) {
                    return const SizedBox.shrink();
                  } else {
                    return Center(
                        child: CircularProgressIndicator(value: value));
                  }
                },
              )
            ],
          );
        });

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      onDoubleTap: _onDoubleTap,
      onDoubleTapDown: _onDoubleTapDown,
      child: Container(
          color: Colors.black,
          child: InteractiveViewer(
              maxScale: _zoomInMaxScale,
              boundaryMargin: EdgeInsets.zero,
              transformationController: _transformationController,
              child: child)),
    );
  }
}
