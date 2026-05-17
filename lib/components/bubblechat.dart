import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class FBubbleChat extends StatelessWidget {
  final String text;
  final Bubbletail tailPosition;

  const FBubbleChat({
    super.key,
    required this.text,
    this.tailPosition = Bubbletail.left,
  });

  EdgeInsets get _bubblePadding {
    switch (tailPosition) {
      case Bubbletail.left:
        return const EdgeInsets.only(left: 24, top: 16, right: 16, bottom: 16);
      case Bubbletail.right:
        return const EdgeInsets.only(left: 16, top: 16, right: 24, bottom: 16);
      case Bubbletail.none:
        return const EdgeInsets.all(16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(tailPosition: tailPosition),
      child: Padding(
        padding: _bubblePadding,
        child: Text(
          text,
          style: fMediumTextStyle.copyWith(
            fontSize: 14,
            color: Colors.black,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Bubbletail tailPosition;

  _BubblePainter({required this.tailPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    const radius = 12.0;
    const tailWidth = 12.0;
    const tailHeight = 16.0;
    final tailY = size.height * 0.3;

    if (tailPosition == Bubbletail.none) {
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius),
        ),
      );
    } else if (tailPosition == Bubbletail.left) {
      path.moveTo(radius + tailWidth, 0);
      path.lineTo(size.width - radius, 0);
      path.arcToPoint(Offset(size.width, radius),
          radius: const Radius.circular(radius));
      path.lineTo(size.width, size.height - radius);
      path.arcToPoint(Offset(size.width - radius, size.height),
          radius: const Radius.circular(radius));
      path.lineTo(radius + tailWidth, size.height);
      path.arcToPoint(Offset(tailWidth, size.height - radius),
          radius: const Radius.circular(radius));
      path.lineTo(tailWidth, tailY + tailHeight);
      path.lineTo(0, tailY + (tailHeight / 2));
      path.lineTo(tailWidth, tailY);

      path.lineTo(tailWidth, radius);
      path.arcToPoint(const Offset(radius + tailWidth, 0),
          radius: const Radius.circular(radius));
    } else if (tailPosition == Bubbletail.right) {
      path.moveTo(radius, 0);
      path.lineTo(size.width - tailWidth - radius, 0);
      path.arcToPoint(Offset(size.width - tailWidth, radius),
          radius: const Radius.circular(radius));
      path.lineTo(size.width - tailWidth, tailY);
      path.lineTo(size.width, tailY + (tailHeight / 2));
      path.lineTo(size.width - tailWidth, tailY + tailHeight);

      path.lineTo(size.width - tailWidth, size.height - radius);
      path.arcToPoint(Offset(size.width - tailWidth - radius, size.height),
          radius: const Radius.circular(radius));
      path.lineTo(radius, size.height);
      path.arcToPoint(Offset(0, size.height - radius),
          radius: const Radius.circular(radius));
      path.lineTo(0, radius);
      path.arcToPoint(const Offset(radius, 0),
          radius: const Radius.circular(radius));
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.tailPosition != tailPosition;
  }
}
