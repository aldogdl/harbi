
import 'test_connection.dart';
import '../config/globals.dart';
import '../config/sng_manager.dart';
import '../services/get_paths.dart';
import '../providers/terminal_provider.dart';

class TestConn {

  static final Globals _globals = getSngOf<Globals>();
  String ipRemota = '';

  /// Probamos primero la conexión local para ver si las url o ip son correctas
  static Future<String> local(TerminalProvider prov) async {

    String isOk = 'sin';
    String uriOk= '';
    String path = await GetPaths.getDominio();
    
    if (!path.contains('_ip_')) {
      prov.setAccs('[-] $path');
      isOk = await TestConnection.go(isLocal: true);
      if(isOk.startsWith('http')) {
        uriOk = isOk;
        isOk = 'ok';
      }
    }

    if (isOk != 'ok') {
      if(_globals.ipHarbi.isNotEmpty) {
        prov.setAccs('[-] Probando: ${_globals.ipHarbi}');
        isOk = await TestConnection.go(isLocal: true, ip: _globals.ipHarbi);
        if(isOk.startsWith('http')) {
          uriOk = isOk;
          isOk = 'ok';
        }
      }
    }

    if (isOk == 'ok') {
      await _setUri('local', uriOk);
      prov.setAccs('[√] Conexión LOCAL Exitosa');
      return isOk;
    }else{
      return _analizarResult(isOk, 'local');
    }
  }

  /// Con el dominio principal probamos para ver si hay respuesta de parte del servidor
  /// en caso contrario se solicita al usuario ingrese una url o ip validas
  static Future<String> remota(TerminalProvider prov) async {

    String isOk = await TestConnection.go();

    if (isOk.startsWith('http')) {
      await _setUri('remoto', isOk);
      prov.setAccs('[√] Conexión REMOTA Exitosa');
      return 'ok';
    }else{
      _globals.workOnlyLocal = false;
      return _analizarResult(isOk, 'remoto');
    }
  }

  ///
  static String _analizarResult(String result, String tipo) {

    String res = 'ask_$tipo';
    if(result.startsWith('http')) {
      return res;
    }
    if(result == 'sin') {
      return res;
    }

    return '[X] ERROR INESPERADO NO HAY CONEXIÓN';
  }

  ///
  static Future<void> _setUri(String tipo, String url) async {

    final uri = Uri.parse(url);
    if(tipo == 'local') {
      _globals.bdLocal = uri.host;
      await GetPaths.setBaseDbLocal(uri.host);
    }else{
      _globals.bdRemota = uri.host;
    }
  }
}
