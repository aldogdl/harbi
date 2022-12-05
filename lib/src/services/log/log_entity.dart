class LogEntity {

  String nReg = '1';
  String file = '';
  String metodo = '';
  String linea = '';
  String column = '';
  String acc = '';
  String res = '';
  String fecha = '';
  String hora = '';

  ///
  Map<String, dynamic> toJson() {

    final f = DateTime.now();
    fecha = '${ "${f.day}".padLeft(2,'0') }/${ "${f.month}".padLeft(2,'0') }/${f.year}';
    hora  = '${f.hour}:${f.minute}:${f.second}';

    return {
      'nReg': nReg,
      'acc': acc,
      'res': res,
      'file': file,
      'metodo': metodo,
      'linea': linea,
      'column': column,
      'fecha': fecha,
      'hora': hora,
    };
  }
}