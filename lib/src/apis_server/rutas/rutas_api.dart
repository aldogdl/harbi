
import '../get_system_file.dart';
import '../ordenes_api.dart';

class RutasApi {

  static List<Map<String, dynamic>> get() {
    
    const String api = '/api_harbi';
    return [
      {'method':'get','path':'$api/get_ipdb', 'page':GetSysemFile(fnc: 'getIpDb')},
      {'method':'get','path':'$api/get_path_prod_ver', 'page':GetSysemFile(fnc: 'getPathProdVersion')},
      {'method':'get','path':'$api/get_path_prod', 'page':GetSysemFile(fnc: 'getPathProd')},
      {'method':'get','path':'$api/get_cargos', 'page':GetSysemFile(fnc: 'getCargos')},
      {'method':'get','path':'$api/get_roles', 'page':GetSysemFile(fnc: 'getRoles')},
      {'method':'get','path':'$api/get_all_rutas', 'page':GetSysemFile(fnc: 'getAllRutas')},
      {'method':'get','path':'$api/get_autos', 'page':GetSysemFile(fnc: 'getAutos')},
      {'method':'get','path':'$api/get_centinela', 'page':GetSysemFile(fnc: 'getCentinela')},
      {'method':'post','path':'$api/set_conection', 'page':GetSysemFile(fnc: 'setConnection')},
      {'method':'get','path':'$api/get_ordenes/:ords', 'page':OrdenesApi(fnc: 'getOrdenesByIds')}
    ];
  }
}