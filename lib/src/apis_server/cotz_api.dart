import 'package:get_server/get_server.dart';

import '../services/get_paths.dart';

class CotzApi extends GetView {

  final Map<String, dynamic> result = {'abort':false, 'msg':'ok', 'body':''};
  final Map<String, dynamic> filtros = {};

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _determinarFnc(context),
      builder: (_, snap) {

        if(snap != null && snap.connectionState == ConnectionState.done) {
          filtros.clear();
          return Json(result);
        }
        return const WidgetEmpty();
      },
    );
  }

  ///
  Future<void> _determinarFnc(BuildContext context) async {

    result['body'] = {};
    String params = context.param('id') ?? '';

    if(params.startsWith('p')) {
      // Se requieren todos los cotizadores paginados si hay más de 10
      params = params.replaceAll('p', '').trim();
      await _getAllPageing(params);
      return;
    }

    await _getById(params);
    return;
  }

  ///
  Future<void> _getById(String id) async {

    final all = await _getCotizadoresFromFile();
    if(all.isNotEmpty) {
      final res = all.where((c) => '${c['c_id']}' == id);
      if(res.isNotEmpty) {
        result['body'] = res.first;
      }
    }
    return;
  }

  /// 
  Future<void> _getAllPageing(String query) async {

    Map<String, dynamic> response = { 'page': '', 'cotz': [] };
    const int maxResult = 11;
    final all = await _getCotizadoresFromFile();

    if(all.isNotEmpty) {
      if(all.length > 10) {

        if(query == '0') {
          response['page'] = maxResult -1;
          response['cotz'] = all.getRange(0, maxResult).toList();
        }else{
          int? ini = int.tryParse(query);
          if(ini != null) {
            final tot = ini + (ini+maxResult);
            if(tot > all.length) {

              if(ini > all.length){ result['body'] = {}; return; }

              response['page'] = '${(ini+all.length)-1}';
              response['cotz'] = all.getRange(ini, all.length).toList();
            }else{
              response['page'] = '${(ini+maxResult)-1}';
              response['cotz'] = all.getRange(ini, ini+maxResult).toList();
            }
          }
        }
      }else{
        response['page'] = '0';
        response['cotz'] = all;
      }
    }
    
    response['filtros'] = _getFiltros(response['cotz']);
    result['body'] = response;
  }

  ///
  Map<String, dynamic> _getFiltros(List<Map<String, dynamic>> cotz) {

    if(filtros.isEmpty) { return {}; }
    Map<String, dynamic> filts = {};

    if(cotz.isNotEmpty) {
      for (var i = 0; i < cotz.length; i++) {
        final idE = '${cotz[i]['e_id']}';
        if(filtros.containsKey(idE)) {
          filts.putIfAbsent(idE, () => filtros[idE]);
        }
      }
    }
    return filts;
  }

  ///
  Future<List<Map<String, dynamic>>> _getCotizadoresFromFile() async {

    var cotz = Map<String, dynamic>.from(await GetPaths.getContentFileOf('cotizadores'));
    if(cotz.containsKey('body')) {
      cotz = cotz['body'];
      if(cotz.isNotEmpty) {
        final f = Map<String, dynamic>.from(cotz['filtros']);
        f.forEach((key, value) {
          filtros.putIfAbsent(key, () => value);
        });
        return List<Map<String, dynamic>>.from(cotz['cotz']);
      }
    }
    return [];
  }

}