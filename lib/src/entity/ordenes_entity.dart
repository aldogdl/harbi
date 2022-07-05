import 'piezas_entity.dart';

class OrdenesEntity {

  int id = 0;
  int anio = 0;
  int own = 0;
  int? avo;
  int marca = 0;
  int modelo = 0;
  DateTime createdAt = DateTime.now();
  String est = '';
  String stt = '';
  bool isNac = true;
  List<PiezasEntity> piezas = [];
  
  ///
  void fromJson(Map<String, dynamic> json) {
    
    id = json['id'];
    anio = json['anio'];
    own = json['own']['id'];
    avo = (json['avo'] != null) ? json['avo']['id'] : null;
    marca = json['marca']['id'];
    modelo = json['modelo']['id'];
    createdAt = DateTime.parse(json['createdAt']['date']);
    est = json['est'];
    stt = json['stt'];
    isNac = json['isNac'];
  }

  ///
  Map<String, dynamic> toServer() {

    return {
      'id': id,
      'anio': anio,
      'own': own,
      'avo': avo,
      'id_marca': marca,
      'id_modelo': modelo,
      'createdAt': createdAt.toIso8601String(),
      'est': est,
      'stt': stt,
      'is_nacional': isNac,
      'local':true,
      'piezas': piezas.map((e) => e.toServer()).toList()
    };
  }

}