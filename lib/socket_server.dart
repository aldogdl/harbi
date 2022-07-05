import 'package:get_server/get_server.dart';

import 'src/apis_server/rutas/rutas_api.dart';
import 'src/config/sng_manager.dart';
import 'src/config/globals.dart';
import 'src/api_socket/my_socket.dart';

class SocketServer {

  final _globals = getSngOf<Globals>();
  
  Widget create() {

    final app = GetServer(host: _globals.ipHarbi, port: _globals.portHarbi);

    app.ws(MySocket.path, (ws) => MySocket.fnc(ws));
    
    RutasApi.get().map((r){
      if(r['method'] == 'get') {
        app.get(r['path'], (ctx) => r['page']);
      }else{
        app.post(r['path'], (ctx) => r['page']);
      }
    }).toList();
    
    return app;
  }
}