
import '../../config/globals.dart';
import '../../config/sng_manager.dart';
import '../../providers/socket_conn.dart';

class ConectadosCheck {

  static final _globals = getSngOf<Globals>();

  ///
  static Future<void> checarMiembrosConectados(SocketConn socket) async {
    
    final int cantAc = _globals.conectados.length;
    
    final ahora = DateTime.now();
    for (var i = 0; i < cantAc; i++) {
      final last = _globals.conectados[i].echo.difference(ahora);
      if(last.inMinutes > 3) {
        _globals.conectados.removeAt(i);
      }
    }
    socket.setRefreshConectados(!socket.refreshConectados);
  }
}