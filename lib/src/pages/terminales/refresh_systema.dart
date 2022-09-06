import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/terminal_skel.dart';
import '../../widgets/txt_terminal.dart';
import '../../providers/terminal_provider.dart';

class RefreshSystema extends StatefulWidget {

  const RefreshSystema({Key? key}) : super(key: key);

  @override
  State<RefreshSystema> createState() => _RefreshSystemaState();
}

class _RefreshSystemaState extends State<RefreshSystema> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_initWidget);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return TerminalSkel(
      child: Selector<TerminalProvider, List<String>>(
        selector: (_, prov) => prov.accs,
        builder: (context, accs, __) => _lstAcc(accs)
      ),
    );
  }

  ///
  Widget _lstAcc(List<String> acc) {

    return ListView(
      controller: ScrollController(),
      children: acc.map((e) => TxtTerminal(
        acc: e, lenTxt: context.read<TerminalProvider>().lenTxt,
      )).toList(),
    );
  }

  ///
  Future<void> _initWidget(_) async {

    final tprod = context.read<TerminalProvider>();
    tprod.accs = [];
    tprod.setAccs('Refrescando Sistema >_');
    await Future.delayed(const Duration(milliseconds: 1000));

    tprod.secc = 'initShell';
  }

}