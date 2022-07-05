import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/my_theme.dart';

class TxtTerminal extends StatelessWidget {

  final String acc;
  const TxtTerminal({
    Key? key,
    required this.acc
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
    return Text(
      acc,
      style: GoogleFonts.inconsolata(
        fontSize: 13, color: color
      ),
    );
  }
}