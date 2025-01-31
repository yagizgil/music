import 'package:flutter/material.dart';

class ScrollToTopButton extends StatefulWidget {
  final ScrollController scrollController;
  final String heroTag;

  const ScrollToTopButton({
    super.key,
    required this.scrollController,
    required this.heroTag,
  });

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton> {
  late final ValueNotifier<bool> _showButton;

  @override
  void initState() {
    super.initState();
    _showButton = ValueNotifier(false);
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _showButton.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showButton = widget.scrollController.hasClients &&
        widget.scrollController.offset > 200;
    if (_showButton.value != showButton) {
      _showButton.value = showButton;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showButton,
      builder: (context, show, child) {
        return AnimatedScale(
          scale: show ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 10.0), // MiniPlayer için boşluk
            child: FloatingActionButton(
              mini: true,
              heroTag: widget.heroTag,
              onPressed: show
                  ? () {
                      widget.scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
              child: const Icon(Icons.arrow_upward),
            ),
          ),
        );
      },
    );
  }
}
