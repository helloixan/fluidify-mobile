import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

// Syntax Parser
class LatexSyntax extends md.InlineSyntax {
  LatexSyntax() : super(r'(\$\$?)([\s\S]+?)\1');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isDisplay = match[1] == '\$\$';
    final latexCode = match[2];

    final element = md.Element.empty('span');
    element.attributes['display'] = isDisplay.toString();
    element.attributes['content'] = latexCode ?? '';

    parser.addNode(element);
    return true;
  }
}

// Element Builder
class LatexBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // PERUBAHAN 2: Ambil teks dari atribut, bukan textContent
    String text = (element.attributes['content'] ?? '').trim();
    final isDisplay = element.attributes['display'] == 'true';

    if (!isDisplay) {
      text = text.replaceAll('\n', ' ').trim();
    }

    Widget mathWidget = Math.tex(
      text,
      mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
      textStyle: preferredStyle?.copyWith(color: Colors.black),
      onErrorFallback: (FlutterMathException e) {
        return Text(text, style: const TextStyle(color: Colors.redAccent));
      },
    );

    if (isDisplay) {
      // Jika block ($$), wajar jika diberi jarak atas-bawah
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: mathWidget,
      );
    }

    // PERUBAHAN 3: Langsung kembalikan mathWidget!
    // HARAM hukumnya membungkus widget inline dengan Wrap, Container, atau Padding
    // agar Flutter menganggapnya sebagai bagian utuh dari karakter teks.
    return mathWidget;
  }
}
