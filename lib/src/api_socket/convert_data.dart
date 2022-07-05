import 'dart:convert';

class ConvertData {

  ///
  static Map<String, dynamic> toJson(String data) {

    Map<String, dynamic> result = {};
    List<int> lstInt = [];
    if(data.isNotEmpty) {
      List<String> partes = data.split(',');
      
      partes.map((e) {
        if(e.startsWith('[')) {
          e = e.replaceFirst('[', '').trim();
        }
        if(e.endsWith(']')) {
          e = e.replaceFirst(']', '').trim();
        }
        lstInt.add(int.parse(e));
      }).toList();

      final r = utf8.decode(lstInt);
      result = json.decode(r);
    }
    return result;
  }
}