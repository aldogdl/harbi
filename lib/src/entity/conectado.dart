class Conectado {

  int cnt = 0;
  String ip = '0';
  String app = '0';
  String id = '0';
  String idCon = '0';
  String curc = '0';
  String name = '0';
  String pass = '0';
  List<String> roles = [];
  DateTime echo;

  Conectado({required this.echo});

  ///
  void fromPing(Map<String, dynamic> data) {

    ip   = data['ip'];
    app  = data['app'];
    idCon= '${data['id']}';
    curc = data['username'];
    name = data['user'];
    pass = '${data['password']}';
  }

  ///
  void fromJson(Map<String, dynamic> data) {

    cnt  = data['cnt'];
    ip   = data['ip'];
    app  = data['app'];
    id   = '${data['id']}';
    idCon= '${data['idCon']}';
    curc = data['curc'];
    roles= List<String>.from(data['roles']);
    name = data['name'];
    pass = '${data['pass']}';
  }

  ///
  Map<String, dynamic> toJson() {

    return {
      'cnt' : cnt,
      'ip'  : ip,
      'app' : app,
      'id'  : id,
      'idCon':idCon,
      'curc': curc,
      'roles': roles,
      'name': name,
      'pass': pass,
      'echo': echo.toIso8601String(),
    };
  }

  ///
  Map<String, dynamic> toConectados() => {
    'idCon': idCon, 'name': name, 'app': app
  };
}