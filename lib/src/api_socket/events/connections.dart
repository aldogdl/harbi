import 'dart:io';
import 'dart:convert';
import 'package:get_server/get_server.dart';

import '../../entity/conectado.dart';
import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../entity/response_event.dart';
import '../../services/get_paths.dart';

class Connections {

  final Globals _globals = getSngOf<Globals>();
  
  final GetSocket ws;
  final String fnc;
  final Map<String, dynamic> params;

  Connections({
    required this.ws,
    required this.fnc,
    required this.params,
  }){

    switch (fnc) {
      case 'edit_user':
        _editUser();
        break;
      case 'ping':
        _ping('ping');
        break;
      default:
    }
  }

  /// 
  Future<void> _ping(String tipo) async {

    int inx = _globals.conectados.indexWhere((e) => e.idCon == '${params['id']}');
    if(inx != -1) {
      _globals.conectados[inx].echo = DateTime.now();
    }else{
      final cntc = Conectado(echo: DateTime.now());
      cntc.fromPing(params);
      _globals.conectados.add(cntc);
    }
  }

  ///
  Future<void> _editUser() async {

    String keyRemove = '';
    Map<String, dynamic> dataConn = {};
    File pass = File(await GetPaths.getFileByPath('connpass'));
    if(pass.existsSync()) {

      dataConn = Map<String, dynamic>.from(json.decode( pass.readAsStringSync() ));

      String passw = params['password'].toString().toLowerCase().trim();
      dataConn.forEach((key, value) {
        if(value['curc'] == params['curc']) {
          dataConn[key]['id'] = params['idC'];
          dataConn[key]['nombre'] = params['nombre'];
          dataConn[key]['roles'] = params['roles'];
          if(passw != 'same-password') {
            keyRemove = key;
          }
        }
      });
      
      if(keyRemove.isNotEmpty) {
        dataConn.putIfAbsent(passw, () => Map<String, dynamic>.from(dataConn[keyRemove]));
        dataConn.remove(keyRemove);
      }
      pass.writeAsStringSync( json.encode(dataConn) );

      if(keyRemove.isNotEmpty) {

        pass = File(await GetPaths.getFileByPath('connwho'));
        String contenido = pass.readAsStringSync();
        if(contenido.isEmpty) { return; }

        var who = List<Map<String, dynamic>>.from( json.decode(contenido) );
        if(who.isNotEmpty) {
          for (var i = 0; i < who.length; i++) {
            if(who[i]['curc'] == params['curc']) {
              who[i]['pass'] = passw;
            }
          }
          pass.writeAsStringSync( json.encode(who) );
        }
      }
    }

    final response = ResponseEvent(event: 'connection', fnc: 'update_colaborador', data: {'msg':'Listo!!'});
    _responser(response);
  }

  ///
  void _responser(ResponseEvent response) {

    final from = ws.getSocketById(params['id']);
    if(from != null) {
      if(response.data.containsKey('err')) {
        response.data['err'] = 'Error, ${response.data['err']}';
      }
      from.send(response.toSend());
    }else{
      // PrintScreen.accSingleErr('[ERROR] NO SE ENCONTRÓ EL ID ${params['id']}, para conectar');
    }
  }
}