import 'package:flutter/material.dart';

class ScrollToTopButton extends StatelessWidget {
  final ScrollController scrollController;
  final String? tooltip;

  const ScrollToTopButton({
    super.key,
    required this.scrollController,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        // Scroll pozisyonu 200'den fazlaysa butonu göster
        final showButton =
            scrollController.hasClients && scrollController.offset > 200;

        return AnimatedOpacity(
          opacity: showButton ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 10.0), // MiniPlayer için boşluk
            child: FloatingActionButton(
              mini: true,
              tooltip: tooltip ?? 'En Başa Dön',
              onPressed: showButton
                  ? () {
                      scrollController.animateTo(
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
