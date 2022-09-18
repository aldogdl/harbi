import 'dart:io';
import 'dart:convert';

import 'package:get_server/get_server.dart';

import '../api_socket/convert_data.dart';
import '../config/globals.dart';
import '../entity/conectado.dart';
import '../config/sng_manager.dart';
import '../services/get_paths.dart';

class GetSysemFile extends GetView {

  final Globals _globals = getSngOf<Globals>();
  final Map<String, dynamic> result = {'abort':false, 'msg':'ok', 'body':''};
  final String fnc;
  GetSysemFile({required this.fnc});

  @override
  Widget build(BuildContext context) {

    if(fnc.startsWith('set')) { return _post(); }

    Future getData = _getFunctions();
    return _get(getData);
  }

  ///
  Widget _get(Future futuro) {

    return FutureBuilder(
      future: futuro,
      builder: (_, snap) {
        if(snap != null && snap.connectionState == ConnectionState.done) {
          return Json(result);
        }
        return const WidgetEmpty();
      },
    );
  }

  ///
  Widget _post() {

    return PayloadWidget(
      builder: (cntx, data) {
        if(data != null) {
          final Map<String, dynamic> map = ConvertData.toJson(data['data']);
          return _get(_postFunctions(map));
        }
        _setResult(true, 'ERROR, No se recibieron datos');
        return Json(result);
      }
    );
  }

  ///
  Future _getFunctions() {

    late Future getData;
    switch (fnc) {
      case 'getPathProdVersion':
        getData = _getPathProdVersion();
        break;
      case 'getPathProd':
        getData = _getPathProd();
        break;
      case 'getCargos':
        getData = _getCargos();
        break;
      case 'getRoles':
        getData = _getRoles();
        break;
      case 'getAutos':
        getData = _getAutos();
        break;
      case 'getCentinela':
        getData = _getCentinela();
        break;
      case 'getAllRutas':
        getData = _getAllRutas();
        break;
      case 'getIpDb':
        getData = _getIpDb();
        break;
      default:
        getData = _unknowFnc();
    }
    return getData;
  }

  ///
  Future _postFunctions(Map<String, dynamic> data) async {

    switch (fnc) {
      case 'setConnection':
        return _setConnection(data);
      default:
    }
    return;
  }

  ///
  Future<void> _getPathProdVersion() async {

    final content = await GetPaths.getContentFilePathShared();
    _setResult(content.isEmpty, 'No hay contenido en el archivo de paths');
    if(content.isNotEmpty) {
      final cont = Map<String, dynamic>.from(content['body']);
      result['body'] = cont['ver'];
    }
  }

  ///
  Future<void> _getPathProd() async {

    final content = await GetPaths.getContentFilePathShared();
    _setResult(content.isEmpty, 'No hay contenido en el archivo de paths');
    if(content.isNotEmpty) {
      result['body'] = Map<String, dynamic>.from(content['body']);
    }
  }
  
  ///
  Future<void> _getCargos() async {

    final content = await GetPaths.getContentFileOf('cargos');
    _setResult(content.isEmpty, 'No hay cargos por el momento.');
    if(content.isNotEmpty) {
      result['body'] = List<String>.from(content['body']);
    }
  }
  
  ///
  Future<void> _getRoles() async {
    final content = await GetPaths.getContentFileOf('roles');
    _setResult(content.isEmpty, 'No hay roles por el momento.');
    if(content.isNotEmpty) {
      result['body'] = List<Map<String, dynamic>>.from(content['body']);
    }
  }
  
  ///
  Future<void> _getAllRutas() async {

    final content = await GetPaths.getContentFileOf('rutas');
    _setResult(content.isEmpty, 'No hay rutas por el momento.');
    if(content.isNotEmpty) {
      result['body'] = Map<String, dynamic>.from(content['body']);
    }
  }

  ///
  Future<void> _getAutos() async {

    final content = await GetPaths.getContentFileOf('autos');
    _setResult(content.isEmpty, 'No hay autos por el momento.');
    if(content.isNotEmpty) {
      result['body'] = List<Map<String, dynamic>>.from(content['body']);
    }
  }

  ///
  Future<void> _getCentinela() async {

    final content = await GetPaths.getContentFileOf('centinela');
    _setResult(content.isEmpty, 'No hay datos en el Centinela.');
    if(content.isNotEmpty) {
      result['body'] = Map<String, dynamic>.from(content['body']);
    }
  }

  ///
  Future<void> _getIpDb() async {

    Map mapa = {};
    File paths = File('${GetPaths.getPathRoot()}${GetPaths.getSep()}${GetPaths.nameFilePathsP}');
    if (paths.existsSync()) {
      mapa = json.decode(paths.readAsStringSync());
    }
    result['body'] = {
      'base_r': mapa['server_remote'],
      'base_l': mapa['server_local'],
      'port_h': mapa['portHarbi'],
      'port_s': mapa['portServer'],
      'type_c': _globals.typeConn,
    };
  }

  ///
  Future<void> _setConnection(Map<String, dynamic> data) async {

    String pathToFile = await GetPaths.getFileByPath('connwho');

    final hoy = DateTime.now();
    data['cnt'] = 1;
    data['date'] = hoy.toIso8601String();

    List<Map<String, dynamic>> content = [];
    final file = File(pathToFile);
    final hasData = file.readAsStringSync();
    if(hasData.isNotEmpty) {

      content = List<Map<String, dynamic>>.from(json.decode(hasData));
      if(content.isEmpty) {
        content.add(data);
      }else{
        
        var user = content.where((user) => user['curc'] == data['curc']).toList();
        int indx = -1;
        if(user.isNotEmpty) {
          for (var i = 0; i < user.length; i++) {
            if(user[i]['app'] == data['app']) {
              indx = i;
              break;
            }
          }
          if(indx != -1) {
            final last = DateTime.parse(content[indx]['date']);
            final diff = hoy.difference(last).inHours;
            data['date'] = hoy.toIso8601String();
            if(diff > 12) {
              data['cnt'] = content[indx]['cnt']+1;
            }
            content[indx] = data;
          }
        }

        if(indx == -1) {
          content.add(data);
        }
      }
    }else{
      content = [data];
    }
    
    file.writeAsStringSync(json.encode(content));
    
    // Buscamos y agregamos a conectado de globals.
    var conectado = Conectado(echo: DateTime.parse(data['date']));
    conectado.fromJson(data);

    int indx = -1;
    if(_globals.conectados.isNotEmpty) {

      final conWho = _globals.conectados.where(
        (user) => user.curc == data['curc']
      ).toList();

      if(conWho.isNotEmpty) {
        for (var i = 0; i < conWho.length; i++) {
          if(conWho[i].app == data['app']) {
            indx = i;
            break;
          }
        }
        if(indx != -1) {
          final diff = hoy.difference(conWho[indx].echo).inMinutes;
          if(diff >= 3) {
            _globals.conectados[indx] = conectado;
          }
        }
      }
    }

    if(indx == -1) {
      _globals.conectados.add(conectado);
    }
  }

  ///
  Future<void> _unknowFnc() async {
    _setResult(true, 'No se encontró la Funcion::$fnc');
  }

  ///
  void _setResult(bool isEmpty, String msgEmpty) {
    
    if(!isEmpty) {
      result['abort']= false;
      result['msg']  = 'ok.';
      result['body'] = '';
    }else{
      result['abort']= true;
      result['msg']  = 'empty';
      result['body'] = msgEmpty;
    }
  }

}