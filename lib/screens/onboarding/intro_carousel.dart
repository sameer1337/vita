import 'package:flutter/material.dart';

/// First-launch walkthrough built from the designer's four full-bleed slides.
/// Each image already contains the Vita logo, stat cards, headline, page dots
/// and the Next / Get Started button, so we just page through them and let a
/// tap (or swipe) advance — the last slide finishes onboarding's intro.
class IntroCarousel extends StatefulWidget {
  const IntroCarousel({super.key, required this.onDone});

  /// Called when the user finishes (or skips) the walkthrough.
  final VoidCallback onDone;

  @override
  State<IntroCarousel> createState() => _IntroCarouselState();
}

class _IntroCarouselState extends State<IntroCarousel> {
  static const _slides = [
    'assets/intro/slide1.png',
    'assets/intro/slide2.png',
    'assets/intro/slide3.png',
    'assets/intro/slide4.png',
  ];

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _advance() {
    if (_index >= _slides.length - 1) {
      widget.onDone();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _controller,
        itemCount: _slides.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => GestureDetector(
          onTap: _advance,
          // Tap the baked-in Next/Get Started button (or anywhere) to advance.
          child: _Slide(asset: _slides[i]),
        ),
      ),
    );
  }
}

/// Shows a slide full-bleed while clipping the mockup's faux status bar off the
/// top so it doesn't clash with the device's real status bar.
class _Slide extends StatelessWidget {
  const _Slide({required this.asset});
  final String asset;

  // Fraction of the image height to keep (top ~6% is the mockup status bar).
  static const double _keep = 0.94;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.bottomCenter,
            minHeight: 0,
            maxHeight: h / _keep,
            child: Image.asset(
              asset,
              width: c.maxWidth,
              height: h / _keep,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
      },
    );
  }
}
