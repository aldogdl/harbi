import 'package:get_server/get_server.dart';

import '../../apis_server/rutas/rutas_api.dart';
import '../../config/sng_manager.dart';
import '../../config/globals.dart';
import '../../api_socket/my_socket.dart';

class SocketServer {

  final _globals = getSngOf<Globals>();
  
  Widget create() {

    final app = GetServer(host: _globals.ipHarbi, port: _globals.portHarbi);

    app.ws(MySocket.path, (ws) {

      RutasApi.get().map((r){
        if(r['method'] == 'get') {
          app.get(r['path'], (ctx) => r['page']);
        }else{
          app.post(r['path'], (ctx) => r['page']);
        }
      }).toList();

      return MySocket.fnc(ws);
    });
    
    return app;
  }
}