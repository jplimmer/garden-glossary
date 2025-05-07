  import 'dart:async';
  import 'package:flutter/material.dart';

  class StreamingTextWidget extends StatefulWidget {
    final TextSpan fullText;
    final Duration characterDuration;
    final bool streaming;
    final VoidCallback? onStreamingComplete;

    const StreamingTextWidget({
      super.key,
      required this.fullText,
      this.characterDuration = const Duration(milliseconds: 5),
      this.streaming = false,
      this.onStreamingComplete,
    });

    @override
    State<StreamingTextWidget> createState() => _StreamingTextWidgetState();
  }

  class _StreamingTextWidgetState extends State<StreamingTextWidget> {
    late Timer _timer;
    int _currentTextLength = 0;
    bool _isStreaming = false;
    String _fullTextString = '';

    @override
    void initState() {
      super.initState();
      _fullTextString = _extractFullText(widget.fullText);
      _setupStreaming();
    }

    @override
    void didUpdateWidget(StreamingTextWidget oldWidget) {
      super.didUpdateWidget(oldWidget);

      if (widget.streaming != oldWidget.streaming ||
        _extractFullText(widget.fullText) != _extractFullText(oldWidget.fullText)) {

          _fullTextString = _extractFullText(widget.fullText);
          _setupStreaming();
        }
    }

    String _extractFullText(TextSpan span) {
      String result = span.text ?? '';

      if (span.children != null) {
        for (var child in span.children!) {
          if (child is TextSpan) {
            result += _extractFullText(child);
          }
        }
      }

      return result;
    }

    void _setupStreaming() {
      if (_isStreaming) {
        _timer.cancel();
      }

      if (widget.streaming) {
        _currentTextLength = 0;
        _isStreaming = true;
        _startStreaming();
      } else {
        _currentTextLength = _fullTextString.length;
        _isStreaming = false;
        setState(() {});
      }
    }

    void _startStreaming() {
      _timer = Timer.periodic(widget.characterDuration, (timer) {
        setState(() {
          if (_currentTextLength < _fullTextString.length) {
            _currentTextLength++;
          } else {
            _timer.cancel();
            _isStreaming = false;
            if (widget.onStreamingComplete != null) {
              widget.onStreamingComplete!();
            }
          }
        });
      });
    }

    @override
    void dispose() {
      if (_isStreaming) {
        _timer.cancel();
      }
      super.dispose();
    }

    TextSpan _buildPartialTextSpan(TextSpan original, int maxLength, int currentPos) {
      String? text = original.text;
      List<InlineSpan>? children;
      int pos = currentPos;

      if (text != null) {
        if (pos >= maxLength) {
          return const TextSpan(text: '');
        }

        int endPos = pos + text.length;
        if (endPos <= maxLength) {
          pos = endPos;
        } else {
          text = text.substring(0, maxLength - pos);
          pos = maxLength;
        }
      }

      if (original.children != null && pos < maxLength) {
        children = [];
        for (var child in original.children!) {
          if (child is TextSpan) {
            TextSpan partialChild = _buildPartialTextSpan(child, maxLength, pos);
            pos += _extractFullText(partialChild).length;
            children.add(partialChild);
          }
        }
      }

      return TextSpan(
        text: text,
        children: children,
        style: original.style,
        recognizer: original.recognizer,
        mouseCursor: original.mouseCursor,
        onEnter: original.onEnter,
        onExit: original.onExit,
        semanticsLabel: original.semanticsLabel,
        locale: original.locale,
        spellOut: original.spellOut,
      );
    }

    @override
    Widget build(BuildContext context) {
      return RichText(
        text: _buildPartialTextSpan(widget.fullText, _currentTextLength, 0),
      );
    }
  }

