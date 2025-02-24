import 'package:flutter/material.dart';
import 'package:garden_glossary/models/id_match.dart';

class IDBox extends StatefulWidget {
  final bool loading;
  final TextSpan loadingText;
  final List<IDMatch> matches;
  final int initialSelectedIndex;
  final Function(int) onMatchSelected;

  const IDBox({
    super.key,
    required this.loading,
    required this.loadingText,
    required this.matches,
    required this.onMatchSelected,
    this.initialSelectedIndex = 0,
  });

  @override
  State<IDBox> createState() => _IDBoxState();
}

class _IDBoxState extends State<IDBox> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late int _selectedIndex;
  late AnimationController _controller;
  late Animation<double> _animation;
  

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  _selectOption(int index) {
    setState(() {
      _selectedIndex = index;
      _isExpanded = false;
    });
    widget.onMatchSelected(index);
  }

  @override
  void didUpdateWidget(covariant IDBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.loading ? null: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.lightGreen[50],
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: widget.loading
                    ? FadeTransition(
                      opacity: _animation,
                      child: RichText(text: widget.loadingText)
                    )
                    : widget.matches[_selectedIndex]
                  ),
                if (!widget.loading)
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
              ],
            ),
            if (!widget.loading && _isExpanded) ...[
              const SizedBox(height: 8),
              const Divider(),
              ... widget.matches.asMap().entries.map((entry) {
                final index = entry.key;
                final match = entry.value;
                if (index == _selectedIndex) return const SizedBox.shrink();

                return InkWell(
                  onTap: () => _selectOption(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: match,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

