import 'package:fluidify_mobile/const/fluidy_const.dart';
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
    return GestureDetector(
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
  }
}
