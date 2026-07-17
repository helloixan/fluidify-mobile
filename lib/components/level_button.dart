import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:flutter/material.dart';

class FluidyLevelButton extends StatefulWidget {
  final VoidCallback action;
  final IconData icon;
  final ButtonStatus state;
  final double size;

  const FluidyLevelButton({
    super.key,
    required this.action,
    this.icon = Icons.star_rounded,
    this.state = ButtonStatus.locked,
    this.size = 90,
  });

  @override
  State<FluidyLevelButton> createState() => _FluidyLevelButtonState();
}

class _FluidyLevelButtonState extends State<FluidyLevelButton> {
  bool _isPressed = false;
  final double _depth = 8.0;
  Color color = Colors.grey[200]!;
  Color shadowColor = Colors.grey[400]!;

  @override
  Widget build(BuildContext context) {
    if (widget.state == ButtonStatus.active) {
      color = regularBlue;
      shadowColor = darkBlue;
    } else if (widget.state == ButtonStatus.locked) {
      color = Colors.grey[200]!;
      shadowColor = Colors.grey[400]!;
    } else if (widget.state == ButtonStatus.done) {
      color = correctGreen;
      shadowColor = Colors.green[700]!;
    }

    String labelText = "";
    bool isLabelLeft = false;
    double labelPosition = 1.0; // Default posisi label di sebelah kanan
    double? labelLeft;
    double? labelRight;

    if (widget.icon == Icons.play_arrow_rounded) {
      labelText = "Simulasi";
      isLabelLeft = true;
      labelPosition = AppSize.screenWidth(context) * 0.45; // Posisi label Simulasi
    } else if (widget.icon == Icons.search_rounded) {
      labelText = "Eksplorasi";
      isLabelLeft = true;
      labelPosition = AppSize.screenWidth(context) * 0.60; // Posisi label Eksplorasi
    } else if (widget.icon == Icons.edit_rounded) {
      labelText = "Peta Konsep";
      isLabelLeft = false;
      labelPosition = 0 - AppSize.screenWidth(context) * 0.20; // Posisi label Peta Konsep
    } else if (widget.icon == Icons.lightbulb) {
      labelText = "Umpan Balik";
      isLabelLeft = false;
      labelPosition = AppSize.screenWidth(context) * 0.22; // Posisi label Umpan Balik
    } else if (widget.icon == Icons.question_mark_rounded) {
      labelText = "Kuis";
      isLabelLeft = false;
      labelPosition = 0 - AppSize.screenWidth(context) * 0.08; // Posisi label Kuis
    }

    Widget button = GestureDetector(
      onTapDown: (_) => setState(() {
        if (widget.state != ButtonStatus.locked) _isPressed = true;
      }),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.state != ButtonStatus.locked){
          widget.action();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.size,
        height: widget.size + _depth - 10,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: widget.size,
                height: widget.size - 10,
                decoration: BoxDecoration(
                  color: shadowColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              bottom: _isPressed ? 0 : _depth,
              child: Container(
                width: widget.size,
                height: widget.size - 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: widget.state == ButtonStatus.active ||
                            widget.state == ButtonStatus.done
                        ? Colors.white
                        : Colors.grey[400],
                    size: widget.size * 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (labelText.isEmpty) {
      return button;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: labelPosition,
          top: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isLabelLeft ? 12 : 0), // Membentuk 'ekor' bubble chat
                bottomRight: Radius.circular(isLabelLeft ? 0 : 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              labelText,
              style: TextStyle(
                color: widget.state == ButtonStatus.locked ? Colors.grey[400] : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
