import 'package:fluidify_mobile/components/bubblechat.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class FluidywithBubble extends StatefulWidget {
  final String text;
  final String maskotPath;
  final Bubbletail position;
  final double maskotSize;
  final bool showMascot;

  const FluidywithBubble(
      {super.key,
      required this.text,
      this.maskotPath = "assets/img/fluidy_hello.png",
      this.maskotSize = 120,
      this.position = Bubbletail.left,
      this.showMascot = true});

  @override
  State<FluidywithBubble> createState() => _FluidywithBubbleState();
}

class _FluidywithBubbleState extends State<FluidywithBubble> {
  @override
  Widget build(BuildContext context) {
    if (widget.position == Bubbletail.left) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.showMascot
              ? Image.asset(
                  widget.maskotPath,
                  width: widget.maskotSize,
                )
              : SizedBox(width: widget.maskotSize), // Menjaga spasi tetap sama
          const SizedBox(width: 8),
          Expanded(
            child: FBubbleChat(
              text: widget.text,
              tailPosition: widget.position,
            ),
          ),
          const SizedBox(width: 8),
        ],
      );
    } else if (widget.position == Bubbletail.right) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: FBubbleChat(
              text: widget.text,
              tailPosition: widget.position,
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            widget.maskotPath,
            width: widget.maskotSize,
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            widget.maskotPath,
            width: widget.maskotSize,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FBubbleChat(
              text: widget.text,
              tailPosition: widget.position,
            ),
          ),
          const SizedBox(width: 8),
        ],
      );
    }
  }
}
