import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// colors
const lightBlue = Color(0xFF03A9F4);
const regularBlue = Color(0xFF039BE5);
const matteBlue = Color(0xFF0288D1);
const darkBlue = Color(0xFF0277BD);
const darkestBlue = Color(0xFF015798);

const lightGreen = Color(0xFFEDF8E8);
const softGreen = Color(0xFFDAEBD1);
const softGray = Color(0xFF49454F);
const softRed = Color(0xFFFFC5CA);
const softBlue = Color(0xFFC3F4FF);
const correctGreen = Color(0xFF00C853);

const darkRed = Color(0xFFB3261E);
const darkOrange = Color(0xFFFFB031);
const appBackgroundColor = Colors.white;

const warningColor = Color(0xFFFF9800);
const dangerColor = Color(0xFFD3302F);

const ColorFilter greyscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

// text styles
final TextStyle fRegularTextStyle =
    GoogleFonts.nunito(fontWeight: FontWeight.w400);
final TextStyle fMediumTextStyle =
    GoogleFonts.nunito(fontWeight: FontWeight.w500);
final TextStyle fSemiBoldTextStyle =
    GoogleFonts.nunito(fontWeight: FontWeight.w600);
final TextStyle fBoldTextStyle =
    GoogleFonts.nunito(fontWeight: FontWeight.w700);
final TextStyle fExtraBoldTextStyle =
    GoogleFonts.nunito(fontWeight: FontWeight.w800);

final TextStyle fHeading1TextStyle =
    GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold);
final TextStyle fHeading2TextStyle =
    GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold);
final TextStyle fHeading3TextStyle =
    GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold);

// Boxshadow
const lightBoxShadow = BoxShadow(
  color: Colors.black26,
  blurRadius: 2,
  spreadRadius: 0,
  offset: Offset(0, 3),
);

// Icons
const streakIcon = Icons.local_fire_department_rounded;

// enum
enum ButtonStatus { active, done, locked }

enum Bubbletail { right, left, none }

enum ChapterStatus { ongoing, done, locked }


