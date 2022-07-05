import 'package:get_server/get_server.dart';
// import '../repository/to_server.dart';

class OrdenesApi extends GetView {

  final Map<String, dynamic> result = {'abort':false, 'msg':'ok', 'body':''};
  final String fnc;
  OrdenesApi({required this.fnc});

  @override
  Widget build(BuildContext context) {
  
    if(fnc.startsWith('set')) { return _post(); }

    final getData = _getFunctions(context);
    return _get(getData);
  }
  
  ///
  Future _getFunctions(BuildContext cntx) async {

    final Map<String?, String?>? params = cntx.request.params;

    switch (fnc) {
      case 'getOrdenesByIds':
        List<String> ords = [];
        if(params != null && params.isNotEmpty) {
          if(params.containsKey('ords')) {
            if(params['ords']!.contains(',')) {
              ords = params['ords']!.split(',');
            }else{
              int? id = int.tryParse(params['ords']!);
              ords = (id == null) ? [] : ['$id'];
            }
          }
        }
        return _getOrdenesByIds(ords);
      default:
        return _unknowFnc();
    }
  }

  ///
  Widget _post() { return const WidgetEmpty(); }

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
  void _setResult(bool isEmpty, String msgEmpty) {
    
    if(!isEmpty) {
      result['abort']= false;
      result['msg']  = 'ok.';
      result['body'] = '';
    }else{
      result['abort']= true;
      result['msg']  = 'empty';
      result['body'] = msgEmpty;
    }
  }

  ///
  Future<void> _unknowFnc() async {
    _setResult(true, 'No se encontró la Funcion::$fnc');
  }

  ///
  Future<bool> _getOrdenesByIds(List<String> ids) async {

    if(ids.isEmpty) {
      _setResult(true, 'No se recibieron ordenes para retornar');
    }
    // await ToServer.setDbLocalOrdPza(ids);
    result['body'] = ids;
    return true;
  }
}