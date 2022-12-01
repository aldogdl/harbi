import 'dart:convert';
import 'dart:io' show File;
import 'package:get_server/get_server.dart';

import '../services/get_paths.dart';

class GetPush extends GetView {

  final Map<String, dynamic> result = {'abort':false, 'msg':'ok', 'body':''};
  final List<String> folds = ['recent', 'lost'];
  final Map<String, dynamic> foldsNames = {'recent': 'pushout', 'lost': 'pushlost'};

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _inToClass(context),
      builder: (_, snap) {

        if(snap != null && snap.connectionState == ConnectionState.done) {
          return Json(result);
        }
        return const WidgetEmpty();
      },
    );
  }

  ///
  Future _inToClass(BuildContext context) async {

    String query = context.param('fnc') ?? '';
    final request = _spellQuery(query);

    if(request.isNotEmpty) {
      return await _determinarEvent(request);
    }
    Future.value(false);
  }

  ///
  Map<String, dynamic> _spellQuery(String query) {

    // querys:
    // recuperar un archivo = <folder%namefile.json> 'lost%4-4-1-orden-1664299434487.json';
    // recuperar nombres de archivos = <folder%tipo-accion> 'lost%2-getnames', 'lost%admin,update-getnames';

    final partes = query.split('%');
    for (var i = 0; i < partes.length; i++) {
      partes[i] = partes[i].trim().toLowerCase();
    }

    if(folds.contains(partes.first)) {

      if(partes.last.endsWith('.json')) {
        return {
          'folder': foldsNames[partes.first], 'file': partes.last
        };
      }else{
        return {
          'fnc': partes.last, 'folder': foldsNames[partes.first]
        };
      }
    }else{
      _setResult(true, 'El Folder no es valido');
    }

    return {};
  }

  ///
  Future<void> _determinarEvent(Map<String, dynamic> request) async {

    if(request.containsKey('fnc')) {

      final partes = request['fnc'].toString().split('-').toList();
      await _determinarFnc(
        request['folder'], {'tipo': partes.first.trim(), 'fnc': partes.last.trim()}
      );
      return;
    }

    await _getContent(request['folder'], request['file']);
  }

  ///
  Future<void> _determinarFnc(String folder, Map<String, dynamic> meta) async {

    switch (meta['fnc']) {
      case 'getnames':
        await _getAllFilesName(folder, meta['tipo']);
        break;
      case '...':
        break;
      default:
    }
  }

  ///
  Future<void> _getAllFilesName(String folder, String tipo) async {

    tipo = tipo.toLowerCase().trim();
    List<String> tipos = [];
    if(tipo.contains(',')) {
      tipos = tipo.split(',');
    }else{
      tipos = [tipo];
    }

    List<String> files = [];
    final dir = GetPaths.getPathsFolderTo(folder);
    if(dir != null) {
      
      dir.listSync().toList().map((file) {
        final filePath = file.path.split(GetPaths.getSep()).last.trim();
        final partes = filePath.split('-');
        if(tipos.contains(partes.first)) {
          files.add(filePath);
        }
      }).toList();
    }

    _setResult(files.isEmpty, json.encode({'files':files}));
    return;
  }

  ///
  Future<Map<String, dynamic>> _getContent(String folder, String file) async {

    file = file.toLowerCase().trim();
    final dir = GetPaths.getPathsFolderTo(folder);
    if(dir != null) {
      final fileP = File('${dir.path}${GetPaths.getSep()}$file');
      if(fileP.existsSync()) {

        final content = fileP.readAsStringSync();
        if(!file.startsWith('centinela_update')) {
          fileP.deleteSync();
        }
        _setResult(false, content);
        return result;
      }
    }
    return {};
  }

  ///
  void _setResult(bool isEmpty, String msgEmpty) {
    
    if(!isEmpty) {
      result['abort']= false;
      result['msg']  = 'ok.';
      result['body'] = msgEmpty;
    }else{
      result['abort']= true;
      result['msg']  = 'empty';
      result['body'] = '[X] $msgEmpty';
    }
  }

}