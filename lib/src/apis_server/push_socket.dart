import 'dart:convert';
import 'package:get_server/get_server.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../config/globals.dart';
import '../config/sng_manager.dart';

class PushSocket extends GetView {

  final Globals _globals = getSngOf<Globals>();

  final Map<String, dynamic> result = {'abort':false, 'msg':'ok', 'body':''};

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _speelParams(context),
      builder: (_, snap) {

        if(snap != null && snap.connectionState == ConnectionState.done) {
          return Json(result);
        }
        return const WidgetEmpty();
      },
    );
  }

  ///
  Future _speelParams(BuildContext context) async {

    IOWebSocketChannel? socket;
    try {
      socket = IOWebSocketChannel.connect(Uri.parse('ws://${_globals.ipHarbi}:${_globals.portHarbi}/socket'));
    } catch (e) {
      _setResult(true, '[X] No se creó correctamente el Socket');
    }

    // Ej. de params
    // event%25self-fnc%25notifAll_UpdateTime-data%25clave=valor,clave2=valor2

    String params = context.param('fnc') ?? '';
    Map<String, dynamic> parse = {};

    if(params.startsWith('event')) {
      
      var partes = params.split('-');
      for (var i = 0; i < partes.length; i++) {
        final claVals = partes[i].split('%');
        parse.putIfAbsent(claVals.first, () => claVals.last);
      }

      if(parse.containsKey('data')) {

        Map<String, dynamic> data = {};
        final laData = parse['data'];

        if(laData.contains('=')) {
          partes = laData.split(',');
          for (var i = 0; i < partes.length; i++) {
            final claVals = partes[i].split('=');
            data.putIfAbsent(claVals.first, () => claVals.last);
          }
        }
        parse['data'] = data;
      }

      if(socket != null) {
        await _makePush(socket, json.encode(parse));
        return Future.value(true);
      }

      _setResult(true, '[X] Sin conexión a Harbi');
    }else{
      if(socket != null) {
        socket.sink.close(status.normalClosure);
      }
      _setResult(true, '[X] Parametros mal formados');
    }   

    return Future.value(false);
  }

  ///
  Future<void> _makePush(IOWebSocketChannel socket, String data) async {

    socket.sink.add(data);
    _setResult(false, '[√] Enviada Notificación');
    socket.sink.close(status.normalClosure);
  }

  ///
  void _setResult(bool isEmpty, String msgEmpty) {
    
    if(!isEmpty) {
      result['abort']= false;
      result['msg']  = 'ok.';
      result['body'] = msgEmpty;
    }else{
      result['abort']= true;
      result['msg']  = 'empty';
      result['body'] = msgEmpty;
    }
  }

}