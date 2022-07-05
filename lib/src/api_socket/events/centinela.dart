import 'dart:io';
import 'dart:convert';

import 'package:get_server/get_server.dart';

import '../../entity/response_event.dart';
import '../../services/get_paths.dart';

class Centinela {

  final GetSocket ws;
  final String fnc;
  final Map<String, dynamic> params;
  Centinela({
    required this.ws,
    required this.fnc,
    required this.params,
  }){
    switch (fnc) {
      case 'all_data':
        _getAllData();
        break;
      default:
    }
  }

  ///
  void _getAllData() async {

    Map<String, dynamic> content = {};
    File dataFile = File(await GetPaths.getFileByPath('centinela'));
    if(dataFile.existsSync()) {
      content = json.decode( dataFile.readAsStringSync() );
    }
    _responser(ResponseEvent(
      event: 'get', fnc: 'all_data', data: content
    ));
  }

  ///
  void _responser(ResponseEvent response) {

    final from = ws.getSocketById(params['id']);
    if(from != null) {
      from.send(response.toSend());
    }else{
      // PrintScreen.accSingleErr('[ERROR] NO SE ENCONTRÓ EL ID ${params['id']}, para conectar');
    }
  }
}