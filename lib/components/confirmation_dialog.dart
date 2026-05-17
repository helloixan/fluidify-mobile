import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class FConfirmationDialog extends StatefulWidget {
  final String? title;
  final String content;
  final String? cancelButtonText;
  final String? confirmButtonText;
  final VoidCallback action;

  const FConfirmationDialog({super.key, this.title, required this.content, this.cancelButtonText, this.confirmButtonText, required this.action});

  @override
  State<FConfirmationDialog> createState() => _FConfirmationDialogState();
}

class _FConfirmationDialogState extends State<FConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: appBackgroundColor,
      title: Text(widget.title ?? 'Konfirmasi Penghapusan', style: fBoldTextStyle),
      content: FluidywithBubble(
        text: widget.content,
        maskotPath: "assets/img/fluidy_confuse.png",
        maskotSize: 100,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(widget.cancelButtonText ?? 'Batal', style: fBoldTextStyle.copyWith(color: softGray)),
        ),
        TextButton(
            onPressed: widget.action,
            child: Text(widget.confirmButtonText ?? 'Yakin', style: fBoldTextStyle.copyWith(color: darkRed))),
      ],
    );
  }
}
