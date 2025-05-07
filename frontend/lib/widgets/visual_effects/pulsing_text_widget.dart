import 'package:flutter/material.dart';

class PulsingText extends StatefulWidget {
  final TextSpan text;
  final Duration duration;
  
  const PulsingText({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<PulsingText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext content) {
    return FadeTransition(
      opacity: _animation,
      child: RichText(
        text: widget.text
      ),
    );
  }
}

