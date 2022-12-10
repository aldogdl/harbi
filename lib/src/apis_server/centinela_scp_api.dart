import 'dart:io';
import 'dart:convert';
import 'package:get_server/get_server.dart';

import '../services/get_paths.dart';
import '../services/my_http.dart';

class CentinelaScpApi  extends GetView  {

  final Map<String, dynamic> result = {'abort':false, 'msg':'ok', 'body':{'metrix':[], 'metas':{}}};
  final Map<String, dynamic> fnc = {'fnc':'', 'query':''};
  final Map<String, dynamic> dataMain = {'folder':'', 'path':'', 'content':{}};
  final List<String> folders = [
    'scm_sended',
    'scm_hist',
    'scm_werr',
    'scm_drash',
    'scm_tray',
    'scm_await'
  ];

  ///
  void clean() {
    result['abort'] = false;
    result['msg']  = 'ok';
    result['body'] = {'metrix':[], 'metas':{}};
  }

  @override
  Widget build(BuildContext context) {
  
    //if(fnc.startsWith('set')) { return _post(); }
    final getData = _getFunctions(context);
    return _get(getData);
  }
  
  ///
  Future _getFunctions(BuildContext cntx) async {

    final Map<String?, String?>? params = cntx.request.params;
    String query = '';
    if(params != null) {
      if(params.containsKey('fnc')) {
        query = params['fnc']!;
      }
    }
    clean();
    
    if(query.isNotEmpty) { _speelQuery(query); }
    if(fnc['fnc'].isNotEmpty) {
      
      switch (fnc['fnc']) {
        case 'get_metrix_of_file' : return await _getMetrixOfFile(); // Borrar
        case 'get_metrix_by_orden': return await _getMetrixByIdOrdenAndIdCamp();
        case 'get_iris_by_orden'  : return await _getIrisByIdOrden();
        case 'get_resp_by_ids'  : return await _getRespuestasByIds();
        default:
          return _unknowFnc();
      }
    }
    
    return _unknowFnc();
  }

  ///
  void _speelQuery(String query) {

    final partes = query.split('=');
    fnc['fnc'] = partes.first.toLowerCase().trim();
    fnc['query'] = partes.last.toLowerCase().trim();
  }

  ///
  Widget _get(Future futuro) {

    return FutureBuilder(
      future: futuro,
      builder: (_, snap) {
        if(snap != null && snap.connectionState == ConnectionState.done) {
          return Json(result);
        }
        return const WidgetEmpty();
      },
    );
  }

  ///
  Future<void> _getMetrixOfFile() async {

    String path = await GetPaths.getUri('get_regs_receivers_by_id_camp');
    List<Map<String, dynamic>> response = [];

    await _fetchFileMain();

    if(!result['abort']) {

      if(dataMain['content'].isNotEmpty) {

        await MyHttp.get('$path${dataMain['content']['id']}/');
        if(!MyHttp.result['abort']) {

          final resp = List<Map<String, dynamic>>.from(MyHttp.result['body']);
          MyHttp.cleanResult();

          final provSended = List<String>.from(dataMain['content']['sended']);
          List<Map<String, dynamic>> contentFiles = await _getContentFiles(provSended, 'scm_sended');
          if(contentFiles.isNotEmpty) {
            response = _sortList(response, contentFiles, resp);
          }

          if(response.isNotEmpty) {
            _setResult(false, '');
            result['body']['metrix'] = response;
            result['body']['metas']['folder'] = dataMain['folder'];
            result['body']['metas']['path'] = dataMain['path'];
            if(dataMain.containsKey('campaings')) {
              result['body']['metas']['camp'] = dataMain['campaings'];
            }
            result['body']['notengo'] = await _getNoTengoByIdOrden(dataMain['content']['id']);
            result['body']['resps'] = await _getRespuestasByIdOrden(dataMain['content']['id']);
          }

        }else{

          _setResult(true, 'No se encontrarón aún registros de Respuestas.');
        }
      }
    }
  }

  ///
  List<Map<String, dynamic>> _sortList
    (
      List<Map<String, dynamic>> response,
      List<Map<String, dynamic>> contentFiles,
      List<Map<String, dynamic>> respHttpRegs
    )
  {

    List<Map<String, dynamic>> resIg = [];
    List<Map<String, dynamic>> resAt = [];
    List<Map<String, dynamic>> resRs = [];
    
    for (var i = 0; i < contentFiles.length; i++) {

      final hasReg = respHttpRegs.firstWhere(
        (el) => el['c_id'] == contentFiles[i]['idReceiver'],
        orElse: () => {}
      );
      if(hasReg.isNotEmpty) {
        Map<String, dynamic> data = {
          'idOrd': dataMain['content']['id'],
          'id': contentFiles[i]['idReceiver'],
          'empresa': contentFiles[i]['receiver']['empresa'],
          'contact': contentFiles[i]['nombre'],
          'curc'   : contentFiles[i]['curc'],
          'created': dataMain['content']['createdAt'],
          'envi'   : (hasReg.isEmpty) ? '0' : hasReg['r_sendAt']['date'],
          'aten'   : (hasReg.isEmpty) ? '0' : (hasReg['r_readAt'] == null) 
            ? '0'
            : hasReg['r_readAt']['date'],
          'stt_clv': (hasReg.isEmpty) ? '0' : hasReg['r_stt'],
          'resps': [],
          'notng': {}
        };

        data['stt_txt'] = _getTextStt(data['stt_clv']);
        if(data['aten'] == '0') {
          resIg.add(data);
        }else{
          if(data['stt_clv'] == 'a') {
            resAt.add(data);
          }else{
            resRs.add(data);
          }
        }
      }
    }

    response.addAll(resRs);
    response.addAll(resAt);
    response.addAll(resIg);
    return response;
  }

  ///
  String _getTextStt(String clv) {

    final txt = {
      'i': 'Ignorado', 'p': 'En Papelera', 'a': 'Atendido', 'r': 'Respondido' 
    };
    return (txt.containsKey(clv)) ? txt[clv]! : 'Desconocido';
  }

  ///
  Future<List<Map<String, dynamic>>> _getRespuestasByIdOrden(int idOrd) async {

    final uri = await GetPaths.getUri('get_resp_centinela');
    await MyHttp.get('$uri$idOrd/');
    if(!MyHttp.result['abort']) {
      return List<Map<String, dynamic>>.from(MyHttp.result['body']);
    }
    return [];
  }

  ///
  Future<Map<String, dynamic>> _getNoTengoByIdOrden(int idOrd) async {

    final filtros = await GetPaths.getContentFileOf('notengo');
    if(filtros.isNotEmpty && filtros.containsKey('body')) {
      if(filtros['body'].isNotEmpty) {
        return (filtros['body'].containsKey('$idOrd')) ? filtros['body']['$idOrd'] : {};
      }
    }
    return {};
  }

  ///
  Future<void> _fetchFileMain() async {

    final root = GetPaths.getPathRoot();
    final s = GetPaths.getSep();

    for (var i = 0; i < folders.length; i++) {

      if(fnc['query'].contains('.json')) {
        final f = File('$root$s${folders[i]}$s${fnc['query']}');
        if(f.existsSync()) {
          dataMain['folder'] = folders[i];
          dataMain['path'] = f.path;
          dataMain['content'] = json.decode(f.readAsStringSync());
          return;
        }

      }else{

        final idOrden = fnc['query'].split('-').first;

        final List<FileSystemEntity> archivos = Directory(
          '$root$s${folders[i]}$s'
        ).listSync().toList();

        if(archivos.isNotEmpty) {
          for (var f = 0; f < archivos.length; f++) {
            final nameFile = archivos[f].path.split(s).last;
            if(nameFile.contains('-${fnc['query']}-')) {
              final f = File('$root$s${folders[i]}$s$nameFile');
              final content = Map<String, dynamic>.from(json.decode(f.readAsStringSync()));
              
              if(content.containsKey('data')) {
                if('${content['data']['id']}' == idOrden) {
                  dataMain['folder'] = folders[i];
                  dataMain['path'] = f.path;
                  dataMain['content'] = content;
                  dataMain['campaings'] = {
                    'orden': '$idOrden',
                    'idCamp': '${content['src']['id']}',
                    'fileCamp': nameFile
                  };
                  return;
                }
              }
            }
          }
        }
      }
    }

    _setResult(true, 'No se ecnontró ${fnc['query']}');
  }

  ///
  Future<List<Map<String, dynamic>>> _getContentFiles(List<String> files, String folder) async {

    List<Map<String, dynamic>> contents = [];
    if(files.isNotEmpty) {

      final root = GetPaths.getPathRoot();
      final s = GetPaths.getSep();
      for (var i = 0; i < files.length; i++) {
        final f = File('$root$s$folder$s${files[i]}');
        if(f.existsSync()) {
          contents.add( 
            Map<String, dynamic>.from(json.decode(f.readAsStringSync()))
           );
        }
      }
    }

    return contents;
  }

  ///
  Future<Map<String, dynamic>> _getMetrixByIdOrdenAndIdCamp() async {

    // Ej Query = get_metrix_by_orden=idOrden:idCamp;

    final s = GetPaths.getSep();
    final String q = fnc['query'];
    final partes = q.split(':');
    String idOrden = partes.first;
    String idCamp  = partes.last;

    // Saber el path del expediente de la orden.
    final pathEx = getFolderExpedienteByIdOrden(idOrden);
    if(pathEx.isNotEmpty) {
      final fCamp = Directory('$pathEx$idCamp');
      if(fCamp.existsSync()) {
        final fMetrix = File('${fCamp.path}$s${"metrix.json"}');
        if(fMetrix.existsSync()) {
          _setResult(false, '');
          result['body'] = fMetrix.readAsStringSync();
          return result;
        }
      }
    }
    return {};
  }

  ///
  Future<Map<String, dynamic>> _getIrisByIdOrden() async {

    // Ej Query = get_iris_by_orden=idOrden;

    final s = GetPaths.getSep();
    String idOrden = fnc['query'];

    // Saber el path del expediente de la orden.
    final pathEx = getFolderExpedienteByIdOrden(idOrden);
    
    _setResult(false, '');
    result['body'] = {};
    if(pathEx.isNotEmpty) {
      final fCamp = Directory(pathEx);
      if(fCamp.existsSync()) {
        final fIris = File('${fCamp.path}$s$idOrden${"_iris.json"}');
        if(fIris.existsSync()) {
          result['body'] = fIris.readAsStringSync();
        }
      }
    }
    return result;
  }

  ///
  Future<Map<String, dynamic>> _getRespuestasByIds() async {

    // Ej Query = get_resp_by_ids=idsVarias;
    // idsVarias= idOrd[i]idPza[i]idResp[i]idCot
    // Ej. 210i1i1i6

    final s = GetPaths.getSep();
    final partes = fnc['query'].toString().split('i');
    _setResult(false, '');
    if(partes.isEmpty) {
      return result;
    }

    // Saber el path del expediente de la orden.
    final pathEx = getFolderExpedienteByIdOrden(partes.first);

    result['body'] = {};
    if(pathEx.isNotEmpty) {
      final exp = File('$pathEx$s${"orden.json"}');
      if(exp.existsSync()) {

        final expC = Map<String, dynamic>.from(json.decode(exp.readAsStringSync()));
        
        if(expC.containsKey('piezas')) {

          final piezas = List<Map<String, dynamic>>.from(expC['piezas']);
          if(piezas.isNotEmpty) {
            final pieza = piezas.where((p) => '${p['id']}' == partes[1]);
            if(pieza.isNotEmpty) {
              if(pieza.first.containsKey('resps')) {
                final resPz = List<Map<String, dynamic>>.from(pieza.first['resps']);
                final pzF = resPz.where((r) {
                  return ('${r['id']}' == partes[2] && '${r['own']}' == partes[3]);
                });
                if(pzF.isNotEmpty) { result['body'] = pzF.first; }
              }
            }
          }
        }
      }
    }

    return result;
  }

  ///
  String getFolderExpedienteByIdOrden(String idOrden) {

    final s = GetPaths.getSep();
    final ords = GetPaths.getPathsFolderTo('ords');
    if(ords != null) {
      final fIndex = File('${ords.path}$s${"index_ords.json"}');
      if(fIndex.existsSync()) {
        final indexC = Map<String, dynamic>.from(json.decode(fIndex.readAsStringSync()));
        if(indexC.isNotEmpty) {
          if(indexC.containsKey(idOrden)) {
            return '${ords.path}$s${indexC[idOrden]}$s$idOrden$s';
          }
        }
      }
    }
    return '';
  }

  ///
  Future<void> _unknowFnc() async {
    _setResult(true, 'No se encontró la página solicitada.');
  }

  ///
  void _setResult(bool isEmpty, String msgEmpty) {
    
    if(!isEmpty) {
      result['abort']= false;
      result['msg']  = 'ok.';
      result['body'] = {'metrix':[], 'metas':{}};
    }else{
      result['abort']= true;
      result['msg']  = 'empty';
      result['body'] = msgEmpty;
    }
  }

}