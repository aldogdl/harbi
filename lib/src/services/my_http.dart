import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/sng_manager.dart';
import '../config/globals.dart';
import 'get_paths.dart';
import 'log/i_log.dart';

class MyHttp {
  
  static Map<String, dynamic> result = {
    'abort': false,
    'msg': 'ok',
    'body': {}
  };
  static Globals globals = getSngOf<Globals>();

  ///
  static cleanResult() {
    result = {'abort': false, 'msg': 'ok', 'body': {}};
  }

  ///
  static Future<void> getApi(Uri uri) async {

    final res = await http.get(uri);
    if(res.statusCode == 200) {
      result = Map<String, dynamic>.from(json.decode(res.body));
    }else{
      result['abort'] = true;
      result['msg'] = 'Error ${res.statusCode}';
      result['body'] = 'Error en el servidor';
    }
  }

  ///
  static Future<String> goUri(String uri) async {
    
    try {
      await get(uri);
      return (result['body'] != 'ok') ? 'no' : uri;
    } catch (e) {
      Ilog(
        StackTrace.current, acc: 'Realizando Conexión con $uri',
        res: e.toString()
      );
      return 'er';
    }
  }

  ///
  static Future<String> go({bool isLocal = false, String ip = ''}) async {
    
    String url = await GetPaths.getUri('check_connx', isLocal: isLocal);
    if (ip.isNotEmpty) { url = _replaceHost(url, ip, isLocal); }
    return await goUri(url);
  }

  /// Remplazamos el host por la ip idicada
  static String _replaceHost(String url, String ip, bool isLocal) {

    late Uri uri;
    if (url.contains('_ip_')) {
      url = url.replaceFirst('_ip_', ip);
      uri = Uri.parse(url);
    }else{
      uri = Uri.parse(url);
      uri = uri.replace(host: ip);
    }

    if (!uri.toString().startsWith('http')) {
      if (isLocal) {
        uri = Uri.http(uri.toString(), uri.fragment);
      } else {
        uri = Uri.https(uri.toString(), uri.fragment);
      }
    }

    return uri.toString();
  }

  ///
  static Future<void> get(String uri) async {

    Uri url = Uri.parse(uri);
    http.Response response = await http.get(url);
    if (response.statusCode == 200) {
      result = Map<String, dynamic>.from(json.decode(response.body));
    } else {
      result['abort'] = true;
      result['msg'] = 'Error ${response.statusCode}';
      result['body'] = 'Error en el servidor';
    }
    return;
  }

  ///
  static Future<void> post(String uri, Map<String, dynamic> data) async {

    Uri url = Uri.parse(uri);
    
    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var req = http.MultipartRequest('POST', url);
    req.headers.addAll(headers);
    req.fields['data'] = json.encode(data);
    final response = await http.Response.fromStream(await req.send());

    if (response.statusCode == 200) {
      result = Map<String, dynamic>.from(json.decode(response.body));
    } else {
      result['abort'] = true;
      result['msg'] = 'Error ${response.statusCode}';
      result['body'] = 'Error en el servidor';
    }
    return;
  }

  ///
  static Future<String> makeLogin(data) async {

    bool isLocal = (globals.env == 'dev') ? true : false;

    String dom = await GetPaths.getDominio(isLocal: isLocal);
    String base = 'secure-api-check';
    http.Response resp = await http.post(Uri.parse('$dom$base'),
      body: json.encode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json'
      }
    );
    
    if (resp.statusCode == 200) {
      final r = Map<String, dynamic>.from(json.decode(resp.body));
      if (r.containsKey('token')) {
        return r['token'];
      }
    }

    return 'Credenciales Invalidas';
  }


}
