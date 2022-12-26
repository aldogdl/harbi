import 'dart:io';
import 'dart:convert';

import '../services/get_paths.dart';
import '../services/my_http.dart';


class FirePushRepository {

  final String fileIndex = 'index_ords.json';
  final s = GetPaths.getSep();

  /// Recuperamos la carpeta donde esta el expediente de la orden
  String getFolderExp(int idOr) {

    final ordsF = GetPaths.getPathsFolderTo('ords');

    if(ordsF != null) {
      final i = File('${ordsF.path}$s$fileIndex');
      if(i.existsSync()) {
        final data = i.readAsStringSync();
        if(data.isNotEmpty) {
          final content = Map<String, dynamic>.from(json.decode(data));
          if(content.isNotEmpty) {
            if(content.containsKey('$idOr')) {
              return '${ordsF.path}$s${content['$idOr']}$s$idOr$s';
            }
          }
        }
      }
    }
    return '';
  }

  /// Revisamos si le hemos enviado una notificación al cotizador, si es así,
  /// revisamos que hallan pasado 2 horas para poderle enviar otra.
  Future<List<int>> checkFrecuencia(List<int> idCotz) async {

    final path = await GetPaths.getFileByPath('firepush');
    final frec = File(path);
    Map<String, dynamic> res = {'toSend': [], 'frec': {}};

    if(frec.existsSync()) {
      final txt = frec.readAsStringSync();
      if(txt.isNotEmpty) {
        res = _checkFrecuencia(
          idCotz, Map<String, dynamic>.from(json.decode(txt))
        );
      }else{
        res = _checkFrecuencia(idCotz, <String, dynamic>{});
      }
    }

    return List<int>.from(res['toSend']);
  }

  /// Actualizamos el tiempo de frecuencia de envio de notificaciones
  /// a los cotizadores, que se les envio un push con exito.
  Future<void> updateFrecuencia(List<int> idCotz, Map<String, dynamic> result) async {

    final path = await GetPaths.getFileByPath('firepush');
    final frec = File(path);
    Map<String, dynamic> res = {'frec': {}};
    final unknown = List<int>.from(result['unknown']);
    final invalid = List<int>.from(result['invalid']);
    invalid.addAll(unknown);
    for (var i = 0; i < idCotz.length; i++) {
      if(invalid.contains(idCotz[i])) {
        idCotz.removeAt(i);
      }
    }

    if(frec.existsSync()) {
      final txt = frec.readAsStringSync();
      if(txt.isNotEmpty) {
        res = _checkFrecuencia(
          idCotz, Map<String, dynamic>.from(json.decode(txt))
        );
      }else{
        res = _checkFrecuencia(idCotz, <String, dynamic>{});
      }
      frec.writeAsStringSync(json.encode(res['frec']));
    }

    return;
  }

  ///
  Map<String, dynamic> _checkFrecuencia
    (List<int> idCotz, Map<String, dynamic> frec)
  {

    final time = DateTime.now();
    List<int> toSend = [];
    for (var i = 0; i < idCotz.length; i++) {

      bool isToSend = false;
      if(frec.containsKey('${idCotz[i]}')) {
        final last = DateTime.parse(frec['${idCotz[i]}']);
        final diff = time.difference(last);
        if(diff.inHours > 2) {
          frec['${idCotz[i]}'] = time.toIso8601String();
          isToSend = true;
        }
      }else{
        frec.putIfAbsent('${idCotz[i]}', () => time.toIso8601String());
        isToSend = true;
      }

      if(isToSend) {
        if(!toSend.contains(idCotz[i])) {
          toSend.add(idCotz[i]);
        }
      }
    }

    return {'toSend': toSend, 'frec': frec};
  }

  /// Enviar las notificaciones y liberar orden, es decir, cambiar stt a 2
  Future<Map<String, dynamic>> sendPushTo
    (int idOrden, String idCamp, String avo, List<int> idsCotz, {bool isLocal = false}) async
  {
    MyHttp.cleanResult();
    String uri = await GetPaths.getUri('push_finish_camp', isLocal: isLocal);
    await MyHttp.get('$uri$idOrden/$idCamp/$avo/pfc-${idsCotz.join(',')}/');
    return MyHttp.result;
  }

  /// Enviar las notificaciones y liberar orden, es decir, cambiar stt a 2
  Future<Map<String, dynamic>> liberarOrden(String idOrden, {bool isLocal = false}) async
  {
    MyHttp.cleanResult();
    String uri = await GetPaths.getUri('liberar_ordenes', isLocal: isLocal);
    await MyHttp.get('$uri${"lib-"}$idOrden/');
    return MyHttp.result;
  }

}