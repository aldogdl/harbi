import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../services/get_paths.dart';
import '../../services/my_http.dart';
import '../../providers/terminal_provider.dart';

class TestConn {

  static const base = 'harbi/check-connx/';

  static final _globals = getSngOf<Globals>();
  static String ipRemota = '';
  static String bdTest = '';

  /// Con el dominio principal probamos para ver si hay respuesta de parte del servidor
  /// en caso contrario se solicita al usuario ingrese una url o ip validas
  static Future<String> remota(TerminalProvider prov) async {

    if(_globals.bdRemota.contains('_dom_')) {
      bdTest = _globals.bdRemota.replaceAll('_dom_', GetPaths.package);
    }else{
      bdTest = _globals.bdRemota;
    }
    prov.setAccs('[!] $bdTest');
    String isOk = await MyHttp.goUri('$bdTest$base');
    return _analizarResult(isOk, 'REMOTA', prov);
  }

  /// Probamos primero la conexión local para ver si las url o ip son correctas
  static Future<String> local(TerminalProvider prov) async {

    prov.setAccs('> Buscando AnetDB con: ${_globals.ipHarbi}');
    final uriL = '${_globals.ipHarbi}:${_globals.portdb}/autoparnet/public_html/';
    final res = await MyHttp.goUri('http://$uriL$base');
    return await _analizarResult(res, 'LOCAL', prov );
  }

  ///
  static Future<String> _analizarResult(String result, String tipo, TerminalProvider? prov) async {

    if (result.startsWith('http')) {
      if(tipo == 'REMOTA') {
        _globals.bdRemota = bdTest;
      }else{
        _globals.bdLocal = bdTest;
      }
      if(prov != null) {
        prov.setAccs('[√] Conexión $tipo Exitosa');
        await Future.delayed(const Duration(milliseconds: 250));
      }
      return 'ok';
    }else{

      if(tipo == 'REMOTA') { _globals.workOnlyLocal = true; }

      if(prov != null) {
        prov.setAccs('[X] ${_globals.ipHarbi} ${_globals.typeConn} Inalcansable.');
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
    return 'bad';
  }

  ///
  static Future<String> setIpGlobal() async {

    String isOk = 'sin';
    bdTest = '';
    final pathP = await GetPaths.getContentFilePaths(isProd: true);
    if(pathP != null) {
      if(pathP.isNotEmpty) {
        if(pathP.containsKey('server_local')) {
          if(!pathP['server_local'].contains('_ip_')) {
            bdTest = pathP['server_local'];
          }
        }
      }
    }

    _globals.bdLocal = 'http://_ip_:_port_/_dom_/public_html/';
    if(bdTest.isNotEmpty) {
      isOk = await MyHttp.goUri('$bdTest$base');
      isOk = await _analizarResult(isOk, 'LOCAL', null);
      if(isOk == 'ok') {
        return isOk;
      }
    }

    if(_globals.bdLocal.contains('_ip_')) {
      bdTest = _globals.bdLocal;
      bdTest = bdTest.replaceAll('_ip_', _globals.ipHarbi);
      bdTest = bdTest.replaceAll('_port_', '${_globals.portdb}');
      bdTest = bdTest.replaceAll('_dom_', GetPaths.package);
    }

    return isOk;
  }
}
