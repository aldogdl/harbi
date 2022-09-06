import 'package:get_server/get_server.dart';
import 'package:harbi/src/apis_server/cotz_api.dart';

import '../get_system_file.dart';
import '../ordenes_api.dart';
import '../push_socket.dart';

class RutasApi {

  static const String api = 'api_harbi';
  
  static List<Map<String, dynamic>> get() {
    
    return [
      {'method':'get','path':'/$api/get_ipdb',          'page': _getSysF('getIpDb')},
      {'method':'get','path':'/$api/get_roles',         'page': _getSysF('getRoles')},
      {'method':'get','path':'/$api/get_autos',         'page': _getSysF('getAutos')},
      {'method':'get','path':'/$api/get_cargos',        'page': _getSysF('getCargos')},
      {'method':'get','path':'/$api/get_path_prod',     'page': _getSysF('getPathProd')},
      {'method':'get','path':'/$api/get_all_rutas',     'page': _getSysF('getAllRutas')},
      {'method':'get','path':'/$api/get_centinela',     'page': _getSysF('getCentinela')},
      {'method':'get','path':'/$api/get_path_prod_ver', 'page': _getSysF('getPathProdVersion')},
      {'method':'post','path':'/$api/set_conection',    'page': _getSysF('setConnection')},
      {'method':'get','path':'/$api/get_cotz_by_id/:id','page': CotzApi()},
      {'method':'get','path':'/$api/push/:fnc',         'page': PushSocket()},
      {'method':'get','path':'/$api/get_ordenes/:ords', 'page': OrdenesApi(fnc: 'getOrdenesByIds')}
    ];
  }

  static Widget _getSysF(String fnc) => GetSysemFile(fnc: fnc);
}