import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/terminal_skel.dart';
import '../../providers/terminal_provider.dart';
import '../../providers/socket_conn.dart';
import '../../widgets/txt_terminal.dart';

class ConectSocket extends StatefulWidget {

  const ConectSocket({Key? key}) : super(key: key);

  @override
  State<ConectSocket> createState() => _ConectSocketState();
}

class _ConectSocketState extends State<ConectSocket> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_initWidget);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    return TerminalSkel(
      child: Selector<SocketConn, List<String>>(
        selector: (_, prov) => prov.sockmsg,
        builder: (_, accs, __) {

          if(accs.isNotEmpty) {

            if(accs.first.startsWith('[√]')) {
              Future.delayed(const Duration(milliseconds: 1000), (){
                context.read<SocketConn>().cleanSockmsg();
                context.read<TerminalProvider>().secc = 'downCent';
              });
            }
          }

          return _lstAcc(accs);
        },
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

    final sock = context.read<SocketConn>();
    final tprod = context.read<TerminalProvider>();
    
    sock.cleanSockmsg();
    sock.setSockmsg(''.padRight(tprod.lenTxt, '-'));
    sock.setSockmsg('Conectando el SOCKET >_');
    sock.setSockmsg(''.padRight(tprod.lenTxt, '-'));
    await Future.delayed(const Duration(milliseconds: 2000));

    await Future.delayed(const Duration(milliseconds: 250));
    sock.makeFirstConnection();
  }
}