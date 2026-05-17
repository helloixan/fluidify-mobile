import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class FButtonWidget extends StatefulWidget {
  final String text;
  final VoidCallback action;
  final Color? color;
  final IconData? icon;
  const FButtonWidget({super.key, required this.text, required this.action, this.color, this.icon});

  @override
  State<FButtonWidget> createState() => _FButtonWidgetState();
}

class _FButtonWidgetState extends State<FButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.color ?? regularBlue,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: widget.action,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                ),
              ),
            
            Text(
              widget.text,
              style: fBoldTextStyle.copyWith(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
