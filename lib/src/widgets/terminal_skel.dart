import 'package:flutter/material.dart';

class TerminalSkel extends StatelessWidget {

  final Widget child;
  const TerminalSkel({
    Key? key,
    required this.child
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.all(8),
      color: Colors.black,
      child: child
    );
  }

}