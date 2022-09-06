import 'dart:convert';
import 'package:get_server/get_server.dart';

import 'centinela.dart';
import 'connections.dart';
import '../../entity/response_event.dart';

// import 'entity/response_event.dart';
// import 'eventos/centinela.dart';
// import 'eventos/connections.dart';
// import 'eventos/task_remotas.dart';

class OnMessage {

  final String event;
  final GetSocket ws;
  OnMessage({
    required this.event,
    required this.ws,
  }){
    _determinarEvent(Map<String, dynamic>.from(json.decode(event)));
  }

  ///
  void _determinarEvent(Map<String, dynamic> data) {

    switch (data['event']) {

      case 'self':
        if(data['fnc'] == 'notifAll_UpdateTime') {
          final response = ResponseEvent(
            event: 'from_centinela', fnc: 'cron', data: data['data']
          );
          ws.sendToAll(response.toSend());
        }

        if(data['fnc'] == 'notifAll_UpdateData') {
          final response = ResponseEvent(
            event: 'from_centinela', fnc: 'update', data: data['data']
          );
          ws.sendToAll(response.toSend());
        }
        break;
      case 'connection':
        Connections(ws: ws, fnc: data['fnc'], params: Map<String, dynamic>.from(data['data']));
        break;
      case 'get':
        Centinela(ws: ws, fnc: data['fnc'], params: Map<String, dynamic>.from(data['data']));
        break;
      default:
    }
  }


}