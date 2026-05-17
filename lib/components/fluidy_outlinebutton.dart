import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class FOutlinedButton extends StatefulWidget {
  final String text;
  final VoidCallback action;
  final IconData? icon;
  const FOutlinedButton({super.key, required this.text, required this.action, this.icon});

  @override
  State<FOutlinedButton> createState() => _FOutlinedButtonState();
}

class _FOutlinedButtonState extends State<FOutlinedButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: regularBlue,
          side: const BorderSide(width: 2, color: regularBlue),
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
                  color: regularBlue,
                ),
              ),
            Text(
              widget.text,
              style: fBoldTextStyle.copyWith(color: regularBlue, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
