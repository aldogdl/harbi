import 'dart:io';
import 'dart:convert';

import 'package:harbi/src/config/sng_manager.dart';
import 'package:harbi/src/librerias/changes_misselanius.dart';

import '../config/globals.dart';
import '../services/get_paths.dart';
import '../services/my_http.dart';

class TaskFromServer {

  static final _globals = getSngOf<Globals>();

  ///
  static Future<void> down() async {

    await downLoadDataAutos();
    await getCotizadores();
  }

  ///
  static Future<void> downLoadDataAutos() async {

    String path = await GetPaths.getFileByPath('autos');
    File autos = File(path);
    if(autos.existsSync()) {

      var content = autos.readAsStringSync();
      if(content.isEmpty) {

        final uri = await GetPaths.getUri('get_all_autos');
        await MyHttp.get(uri);
        if(!MyHttp.result['abort']) {
          if(MyHttp.result['body'].isNotEmpty) {
            autos.writeAsStringSync(json.encode(
              List<Map<String, dynamic>>.from( MyHttp.result['body'] )
            ));
          }
        }
      }
    }
  }

  ///
  static Future<void> getCotizadores() async {
    
    final uri = await GetPaths.getUri('get_all_cotz');
    await MyHttp.get(uri);
    if(!MyHttp.result['abort']) {
      final pathCotz = await GetPaths.getFileByPath('cotizadores');
      File(pathCotz).writeAsStringSync(
        json.encode(List<Map<String, dynamic>>.from(MyHttp.result['body']))
      );
    }
  }

  ///
  static Future<void> uploadRutaTo(String hacia) async {

    String path = await GetPaths.getFileByPath('rutas');
    File rutasF = File(path);
    if(rutasF.existsSync()) {
      
      final ruta = Map<String, dynamic>.from( json.decode(rutasF.readAsStringSync()) );
      bool isLocal = false;
      if(hacia == 'local') {
        isLocal = true;
      }
      if(!_globals.workOnlyLocal) {
        isLocal = true;
      }
      String uri = await GetPaths.getUri('save_ruta_last', isLocal: isLocal);
      await MyHttp.post(uri, ruta);
    }
  }

  /// Subimos al servidor todos los datos de conexion de éste harbi
  static Future<void> upDataConnection() async {

    final data = base64Encode( utf8.encode('${_globals.ipHarbi}:${_globals.portHarbi}') );
    
    bool isLocal = (_globals.workOnlyLocal) ? true : false;
    String uri = await GetPaths.getUri('save_ip_address_harbi', isLocal: isLocal);

    if(uri.isNotEmpty) {

      await MyHttp.post(uri, {'key':_globals.passH, 'conx':data});
      if(!MyHttp.result['abort']) {
        String path = await GetPaths.getFileByPath('harbi_connx');
        File file = File(path);
        var toWrite = await GetPaths.getBaseLocalAndRemoto();
        file.writeAsStringSync(json.encode(toWrite));
      }
    }
  }

  ///
  static Future<Map<String, dynamic>> checkCambionEnCentinela(String uri) async {

    await MyHttp.get('$uri${_globals.versionCentinela}');
    if(!MyHttp.result['abort']) {

      var r = Map<String, dynamic>.from(MyHttp.result['body']['changes']);

      bool save = false;
      if(r.containsKey('scm')) {
        if(r['scm'].isNotEmpty) {
          save = true;
        }
      }

      if(!save) {
        if(r.containsKey('scmSee')) {
          save = r['scmSee'];
        }
      }

      if(!save) {
        if(r.containsKey('scmResp')) {
          save = r['scmResp'];
        }
      }

      if(!save) {
        if(r.containsKey('filtros')) {
          if(r['filtros'].isNotEmpty) {
            save = true;
          }
        }
      }

      if(save) {
        r.putIfAbsent('misselanius', () => true);
        await ChangesMisselanius.save(r);
      }
      return r;
    }

    return {'err':'.'};
  }

}
