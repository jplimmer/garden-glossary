import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final String imagePath;
  final double alpha;
  final BlendMode blendMode;

  const BackgroundWidget({
    super.key,
    this.imagePath = 'assets/images/background.jpg',
    this.alpha = 0.5,
    this.blendMode = BlendMode.dstATop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: alpha),
            blendMode,
          ),
        ),
      ),
    );
  }
}