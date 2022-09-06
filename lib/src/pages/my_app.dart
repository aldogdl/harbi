import 'package:flutter/material.dart';

import 'conectados.dart';
import 'data_conection.dart';
import '../widgets/terminales.dart';
import '../config/my_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      color: MyTheme.bgMain,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            flex: 4,
            child: Terminales(),
          ),
          Expanded(
            flex: 3,
            child: Conectados(),
          ),
          Expanded(
            flex: 3,
            child: DataConection(),
          ),
        ],
      )
    );
  }
}