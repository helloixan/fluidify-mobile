import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:flutter/material.dart';

class ChapterBox extends StatefulWidget {
  final String chapterName;
  final String state;

  const ChapterBox(
      {super.key, required this.chapterName, this.state = 'locked'});

  @override
  State<ChapterBox> createState() => _ChapterBoxState();
}

class _ChapterBoxState extends State<ChapterBox> {
  Color color = Colors.grey;

  @override
  Widget build(BuildContext context) {
    if (widget.state == 'current') {
      color = regularBlue;
    } else if (widget.state == 'locked') {
      color = Colors.grey[400]!;
    } else if (widget.state == 'completed') {
      color = correctGreen;
    }
    return Container(
      height: 80,
      width: AppSize.screenWidth(context) - 20,
      decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          boxShadow: const [lightBoxShadow]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(Icons.book_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            widget.chapterName,
            style: fHeading3TextStyle.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
