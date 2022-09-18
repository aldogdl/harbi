import 'dart:io';
import 'dart:convert';

import 'get_paths.dart';
import 'my_http.dart';
import '../config/sng_manager.dart';
import '../config/globals.dart';
import '../providers/terminal_provider.dart';
import '../librerias/f_cron_centinela/changes_misselanius.dart';

class TaskFromServer {

  static final _globals = getSngOf<Globals>();

  ///
  static Future<void> down(TerminalProvider consol) async {

    consol.setAccs('Organizando AUTOS');
    await downLoadDataAutos();
    consol.setAccs('Organizando REMITENTES');
    await getCotizadores(consol);
    consol.setAccs('Información Incial lista');
  }

  ///
  static Future<void> downLoadDataAutos() async {

    final uri = await GetPaths.getUri('get_all_autos');
    await MyHttp.get(uri);
    if(!MyHttp.result['abort']) {
      if(MyHttp.result['body'].isNotEmpty) {
        String path = await GetPaths.getFileByPath('autos');
        File autos = File(path);
        autos.writeAsStringSync(json.encode(
          List<Map<String, dynamic>>.from( MyHttp.result['body'] )
        ));
      }
    }
  }

  ///
  static Future<void> getCotizadores(TerminalProvider consol) async {
    
    consol.setAccs('Buscando Remitentes en SR');
    final uri = await GetPaths.getUri('get_all_cotz');
    await MyHttp.get(uri);
    
    List<Map<String, dynamic>> cotz = [];
    Map<String, List<Map<String, dynamic>>> filts = {};

    if(!MyHttp.result['abort']) {
      final pathCotz = await GetPaths.getFileByPath('cotizadores');
      final cotizs = List<Map<String, dynamic>>.from(MyHttp.result['body']);
      consol.setAccs('Organizando ${cotizs.length} Remitentes.');
      if(cotizs.isNotEmpty) {
        for (var i = 0; i < cotizs.length; i++) {

          var has = cotz.where((c) => c['c_curc'] == cotizs[i]['curc']);
          if(has.isEmpty) {
            cotz.add(_convertCotzToJson(cotizs[i]));
          }

          if(!filts.containsKey(cotizs[i]['empresa']['id'])) {
            filts.putIfAbsent(
              '${cotizs[i]['empresa']['id']}',
              () => _convertFiltroToJson(List<Map<String, dynamic>>.from(cotizs[i]['empresa']['filtros']))
            );
          }
        }
      }

      File(pathCotz).writeAsStringSync(
        json.encode({'cotz': cotz, 'filtros': filts})
      );
    }
  }

  ///
  static Map<String, dynamic> _convertCotzToJson(Map<String, dynamic> data) {

    return {
      'c_id': data['id'],
      'c_curc': data['curc'],
      'c_nombre': data['nombre'],
      'c_cargo': data['cargo'],
      'c_celular': data['celular'],
      'e_id': data['empresa']['id'],
      'e_nombre': data['empresa']['nombre'],
      'e_isLocal': data['empresa']['isLocal'],
    };
  }

  ///
  static List<Map<String, dynamic>> _convertFiltroToJson(List<Map<String, dynamic>> filtros) {

    List<Map<String, dynamic>> resultados = [];

    if(filtros.isNotEmpty) {
      for (var i = 0; i < filtros.length; i++) {

        var has = resultados.where((f) => f['f_id'] == filtros[i]['id']);
        if(has.isEmpty) {

          Map<String, dynamic> mrk = {};
          if(filtros[i]['marca'] != null) {
            mrk = Map<String, dynamic>.from(filtros[i]['marca']);
          }
          Map<String, dynamic> mod = {};
          if(filtros[i]['modelo'] != null) {
            mod = Map<String, dynamic>.from(filtros[i]['modelo']);
          }
          Map<String, dynamic> pza = {};
          if(filtros[i]['pza'] != null) {
            pza = Map<String, dynamic>.from(filtros[i]['pza']);
          }
          resultados.add({
            'f_id': filtros[i]['id'],
            'f_marca': (mrk.isEmpty) ? 0 : mrk['id'],
            'f_modelo': (mod.isEmpty) ? 0 : mod['id'],
            'f_anio': filtros[i]['anio'],
            'f_pieza': (filtros[i]['pieza'] == null) ? '0' : filtros[i]['pieza'],
            'f_pza': (pza.isEmpty) ? 0 : pza['id'],
            'f_grupo': filtros[i]['grupo'],
          });
        }
      }
    }

    return resultados;
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

      bool save = false;
      var r = Map<String, dynamic>.from(MyHttp.result['body']);
      MyHttp.cleanResult();
      
      if(r.containsKey('camping')) {
        save = r['camping'];
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
        if(r.containsKey('filNtg')) {
          if(r['filNtg'] > 9) {
            save = true;
          }
        }
      }

      if(!save) {
        if(r.containsKey('filCnm')) {
          save = r['filCnm'];
        }
      }

      if(r.containsKey('asigns')) {
        await sendNotificationUpdateData();
      }

      if(save) {
        r.putIfAbsent('misselanius', () => true);
        await ChangesMisselanius.save(r);
      }

      return r;
    }

    return {'err':MyHttp.result['body']};
  }

  ///
  static Future<Map<String, dynamic>> sendNotificationUpdateData() async {

    String query = 'event%self-fnc%notifAll_UpdateData-data%'
    'acc=recovery';

    String url = await GetPaths.getApi('push');
    Uri uri = Uri.http('${_globals.ipHarbi}:${_globals.portHarbi}', '$url/$query');
    await MyHttp.getApi(uri);
    return MyHttp.result;
  }

  ///
  static Future<Map<String, dynamic>> sendNotificationUpdateTime() async {

    final time = DateTime.now();
    String query = 'event%self-fnc%notifAll_UpdateTime-data%'
    'time=${time.minute}:${time.second},vers=${_globals.versionCentinela}';

    String url = await GetPaths.getApi('push');
    Uri uri = Uri.http('${_globals.ipHarbi}:${_globals.portHarbi}', '$url/$query');
    await MyHttp.getApi(uri);
    return MyHttp.result;
  }

}
