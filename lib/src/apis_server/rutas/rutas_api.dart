
import 'package:get_server/get_server.dart';

import '../get_system_file.dart';
import '../ordenes_api.dart';

class RutasApi {

  static List<Map<String, dynamic>> get() {
    
    const String api = '/api_harbi';
    return [
      {'method':'get','path':'$api/get_ipdb',          'page': _getSysF('getIpDb')},
      {'method':'get','path':'$api/get_roles',         'page': _getSysF('getRoles')},
      {'method':'get','path':'$api/get_autos',         'page': _getSysF('getAutos')},
      {'method':'get','path':'$api/get_cargos',        'page': _getSysF('getCargos')},
      {'method':'get','path':'$api/get_path_prod',     'page': _getSysF('getPathProd')},
      {'method':'get','path':'$api/get_all_rutas',     'page': _getSysF('getAllRutas')},
      {'method':'get','path':'$api/get_centinela',     'page': _getSysF('getCentinela')},
      {'method':'get','path':'$api/get_path_prod_ver', 'page': _getSysF('getPathProdVersion')},
      {'method':'post','path':'$api/set_conection',    'page': _getSysF('setConnection')},
      {'method':'get','path':'$api/get_ordenes/:ords', 'page': OrdenesApi(fnc: 'getOrdenesByIds')}
    ];
  }

  static Widget _getSysF(String fnc) => GetSysemFile(fnc: fnc);
}