import 'dart:convert';

import 'package:get_server/get_server.dart';

import 'events/on_message.dart';
import '../config/globals.dart';
import '../config/sng_manager.dart';

class MySocket {

  static final Globals _globals = getSngOf<Globals>();
  static const path = '/socket';

  ///
  static void fnc(GetSocket ws) {

    ws.onOpen((socket) async {
      socket.sockets.add(socket);
      socket.send(json.encode({'connId': socket.id}));
    });
    
    ws.onMessage((event) async => OnMessage(event: event, ws: ws));

    ws.onClose((socket) {
      int inx = _globals.conectados.indexWhere((e) => e.idCon == '${socket.socket.id}');
      if(inx != -1) {
        _globals.conectados.removeAt(inx);
      }
    });

  }
}