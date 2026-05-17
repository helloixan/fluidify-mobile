import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class TopStudentProfile extends StatefulWidget {
  final String name;
  final int rank;
  final String avatarUrl;
  final int points;


  const TopStudentProfile({super.key, required this.name, required this.rank, required this.avatarUrl, required this.points});

  @override
  State<TopStudentProfile> createState() => _TopStudentProfileState();
}

class _TopStudentProfileState extends State<TopStudentProfile> {
  @override
  Widget build(BuildContext context) {
    final rankText = widget.rank == 1
        ? "1st"
        : widget.rank == 2
            ? "2nd"
            : widget.rank == 3
                ? "3rd"
                : "${widget.rank}th";
    final color = widget.rank == 1
        ? Colors.amber
        : widget.rank == 2
            ? Colors.grey
            : widget.rank == 3
                ? Colors.brown
                : Colors.blueGrey;

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 4,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: widget.rank == 1 ? 40 : 32,
            backgroundImage: widget.avatarUrl != "" && widget.avatarUrl.isNotEmpty ? NetworkImage(widget.avatarUrl) : null,
            child: widget.avatarUrl == "" || widget.avatarUrl.isEmpty ? Icon(Icons.person, size: 50, color: color) : null,
          ),
        ),
        Row(
          children: [
            Icon(Icons.emoji_events, size: 14, color: color),
            Text(rankText, style: fMediumTextStyle.copyWith(color: color)),
          ],
        ),
        Text(widget.name, style: fSemiBoldTextStyle),
        const SizedBox(height: 5),
        Text("${widget.points} pts",
            style: fMediumTextStyle.copyWith(color: regularBlue)),
      ],
    );
  }
}
