import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'terminal_skel.dart';
import 'txt_terminal.dart';
import '../../providers/terminal_provider.dart';

class CheckSystem extends StatefulWidget {

  const CheckSystem({Key? key}) : super(key: key);

  @override
  State<CheckSystem> createState() => _CheckSystemState();
}

class _CheckSystemState extends State<CheckSystem> {

  List<String> acc = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_initWidget);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => TerminalSkel(child: _lstAcc());

  ///
  Widget _lstAcc() {

    return ListView(
      controller: ScrollController(),
      children: acc.map((e) => TxtTerminal(acc: e)).toList(),
    );
  }

  ///
  Future<void> _initWidget(_) async {

    acc.add('Iniciando SHELL >_');
    setState(() {});

    Future.delayed(const Duration(milliseconds: 3000), (){
      context.read<TerminalProvider>().secc = 'init';
    });
  }
}