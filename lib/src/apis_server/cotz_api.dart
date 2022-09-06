import 'package:get_server/get_server.dart';
import 'package:harbi/src/services/get_paths.dart';

class CotzApi extends GetView {

  final Map<String, dynamic> result = {'abort':false, 'msg':'ok', 'body':''};

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _determinarFnc(context),
      builder: (_, snap) {

        if(snap != null && snap.connectionState == ConnectionState.done) {
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
    var cotz = Map<String, dynamic>.from(await GetPaths.getContentFileOf('cotizadores'));
    if(cotz.containsKey('body')) {
      cotz = cotz['body'];
      if(cotz.isNotEmpty) {
        final all = List<Map<String, dynamic>>.from(cotz['cotz']);
        final res = all.where((c) => '${c['c_id']}' == params);
        if(res.isNotEmpty) {
          result['body'] = res.first;
        }
      }
    }
    return;
  }
}