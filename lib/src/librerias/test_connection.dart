import '../services/get_paths.dart';
import '../services/my_http.dart';

class TestConnection {

  ///
  static Future<String> go({bool isLocal = false, String ip = ''}) async {
    
    String url = await GetPaths.getUri('check_connx', isLocal: isLocal);

    if (ip.isNotEmpty) { url = _replaceHost(url, ip, isLocal); }
    
    try {
      await MyHttp.get(url);
      return (MyHttp.result['body'] != 'ok') ? 'no' : url;
    } catch (e) {
      return 'er';
    }
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
}
