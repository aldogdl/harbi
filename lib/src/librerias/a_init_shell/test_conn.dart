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
      prov.setAccs('> Test con uri ALMACENADA');
      prov.setAccs('[!] $bdTest');
      isOk = await MyHttp.goUri('$bdTest$base');
      isOk = _analizarResult(isOk, 'LOCAL', prov);
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
  
    prov.setAccs('> Test con uri NUEVA');
    prov.setAccs('[!] $bdTest');
    isOk = await MyHttp.goUri('$bdTest$base');
    isOk = _analizarResult(isOk, 'LOCAL', prov);
    return isOk;
  }

  ///
  static String _analizarResult(String result, String tipo, TerminalProvider prov) {

    if (result.startsWith('http')) {
      if(tipo == 'REMOTO') {
        _globals.bdRemota = bdTest;
      }else{
        _globals.bdLocal = bdTest;
      }
      prov.setAccs('[√] Conexión $tipo Exitosa');
      return 'ok';
    }else{
      _globals.workOnlyLocal = (tipo == 'REMOTO') ? true : false;
      prov.setAccs('[X] ERROR, NO HAY CONEXIÓN $tipo');
      return 'ask_${tipo.toLowerCase()}';
    }
  }

}
