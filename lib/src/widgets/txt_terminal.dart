import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/my_theme.dart';

class TxtTerminal extends StatelessWidget {

  final String acc;
  final int lenTxt;
  const TxtTerminal({
    Key? key,
    required this.acc,
    required this.lenTxt
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    Color color = MyTheme.txtMain;
    if(acc.startsWith('[√]')) {
      color = Colors.blue;
    }
    if(acc.startsWith('[X]')) {
      color = Colors.orange;
    }
    if(acc.startsWith('[!]')) {
      color = Colors.amber;
    }
    if(acc.startsWith('[-]')) {
      color = Colors.green;
    }
    
    String txt = acc;
    if(txt.length > lenTxt) {
      txt = txt.substring(0, lenTxt);
      txt = '$txt...';
    }
    return Text(
      txt,
      style: GoogleFonts.inconsolata(
        fontSize: 13,
        color: color,
        height: 1.2
      ),
    );
  }
}