import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'terminal_skel.dart';
import '../../providers/terminal_provider.dart';
import '../../providers/socket_conn.dart';
import 'txt_terminal.dart';

class ConectSocket extends StatelessWidget {

  const ConectSocket({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return TerminalSkel(
      child: Selector<SocketConn, List<String>>(
        selector: (_, prov) => prov.sockmsg,
        builder: (_, accs, __) {

          if(accs.isEmpty) {
            Future.delayed(const Duration(milliseconds: 500), (){
              _initSocket(context);
            });
          }else{
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
      children: acc.map((e) => TxtTerminal(acc: e)).toList(),
    );
  }

  ///
  Future<void> _initSocket(BuildContext context) async {

    final sock = context.read<SocketConn>();

    sock.setSockmsg('> Conectando el SOCKET');
    await Future.delayed(const Duration(milliseconds: 250));
    sock.makeFirstConnection();
  }
}