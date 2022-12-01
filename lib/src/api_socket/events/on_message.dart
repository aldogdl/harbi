import 'dart:convert';

import 'package:get_server/get_server.dart';
import 'package:harbi/src/entity/conectado.dart';

import 'centinela.dart';
import 'connections.dart';
import '../../entity/response_event.dart';
import '../../config/globals.dart';
import '../../config/sng_manager.dart';

class OnMessage {

  final String event;
  final GetSocket ws;
  OnMessage({required this.event, required this.ws}) { _determinarEvent(event); }
  final _globals = getSngOf<Globals>();

  ///
  void _determinarEvent(String event) async {

    Map<String, dynamic> data = {};
    if(event.contains('%')) {
      data = _spellEvent(event);
    }else{
      final req = Map<String, dynamic>.from(json.decode(event));
      if(req.containsKey('fnc')) {
        data = req;
      }
    }

    switch (data['fnc']) {

      case 'pushall':
        final response = ResponseEvent(
          event: 'harbi_push', fnc: data['fnc'],
          data: Map<String, dynamic>.from({'files':data['data']})
        );
        ws.sendToAll(response.toSend());
        break;
      case 'update-time':
        final response = ResponseEvent(
          event: 'from_centinela', fnc: 'update-time',
          data: Map<String, dynamic>.from(data['data'])
        );
        ws.sendToAll(response.toSend());
        break;
      case 'reping':
        await _makeReping(data);
        break;
      case 'update-data':
        final response = ResponseEvent(
          event: 'from_centinela', fnc: 'update', data: data['data']
        );
        ws.sendToAll(response.toSend());
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

  ///
  Map<String, dynamic> _spellEvent(String event) {

    Map<String, dynamic> data = {'fnc': '', 'data': ''};
    List<String> partes = event.split('%');
    data['fnc'] = partes.first;
    if(partes.last.contains('=')) {
      partes = partes.last.split(',');
      for (var i = 0; i < partes.length; i++) {
        partes[i] = partes[i].trim().toLowerCase();
        final keyVal = partes[i].split('=');
        data['data'][keyVal.first.trim().toString()] = keyVal.last.trim();
      }
    }else{
      data['data'] = partes.last;
    }
    return data;
  }

  ///
  Future<void> _makeReping(Map<String, dynamic> data) async {

    final response = ResponseEvent(event: 'harbi', fnc: 'reping', data: {});
    final sockId = ws.getSocketById(data['data']['id']);
    if(sockId != null) {
      if(_globals.conectados.isNotEmpty) {
        final esta = _globals.conectados.indexWhere((e) => e.curc == data['data']['username']);
        if(esta != -1) {
          _globals.conectados[esta].echo = DateTime.now();
        }
      }else{
        final c = Conectado(echo: DateTime.now());
        c.fromPing(data['data']);
        _globals.conectados.add(c);
      }
      if(_globals.conectados.isNotEmpty) {
        for (var i = 0; i < _globals.conectados.length; i++) {
          if(_globals.conectados[i].name == 'Anónimo') {
            _globals.conectados.removeAt(i);
          }
        }
      }
      sockId.send(response.toSend());
    }
  }
}