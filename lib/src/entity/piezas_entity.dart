class PiezasEntity {

  int id = 0;
  int orden = 0;
  String est = '0';
  String stt = '0';
  String piezaName = '0';
  String origen = '0';
  String lado = '0';
  String posicion = '0';
  List<String> fotos = [];
  String obs = '0';
  String idHive = '0';

  ///
  void fromJson(Map<String, dynamic> json) {

    id = json['id'];
    orden = (json.containsKey('orden')) ? json['orden']['id'] : 0;
    est = json['est'];
    stt = json['stt'];
    piezaName = json['piezaName'];
    origen = json['origen'];
    lado = json['lado'];
    posicion = json['posicion'];
    fotos = List<String>.from(json['fotos']);
    obs = (json['obs'].isEmpty) ? '0' : json['obs'];
    idHive = json['idHive'];
  }

  ///
  Map<String, dynamic> toServer() {
    
    return {
      'id': id,
      'orden': orden,
      'est': est,
      'stt': stt,
      'piezaName': piezaName,
      'origen': origen,
      'lado': lado,
      'posicion': posicion,
      'fotos': fotos,
      'obs': obs,
      'idHive': idHive,
      'local':true
    };
  }
}