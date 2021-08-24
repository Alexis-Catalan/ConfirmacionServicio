import 'dart:convert';

InformacionViaje informacionViajeFromJson(String str) => InformacionViaje.fromJson(json.decode(str));

String informacionViajeToJson(InformacionViaje data) => json.encode(data.toJson());

class InformacionViaje {
  String id;
  String status;
  String idTaxista;
  String origen;
  String destino;
  String idHistorialViaje;
  double origenLat;
  double origenLng;
  double destinoLat;
  double destinoLng;

  InformacionViaje({
    this.id,
    this.status,
    this.idTaxista,
    this.origen,
    this.destino,
    this.idHistorialViaje,
    this.origenLat,
    this.origenLng,
    this.destinoLat,
    this.destinoLng,
  });

  factory InformacionViaje.fromJson(Map<String, dynamic> json) => InformacionViaje(
    id: json["id"],
    status: json["status"],
    idTaxista: json["idTaxista"],
    origen: json["origen"],
    destino: json["destino"],
    idHistorialViaje: json["idHistorialViaje"],
    origenLat: json["origenLat"]?.toDouble() ?? 0,
    origenLng: json["origenLng"]?.toDouble() ?? 0,
    destinoLat: json["destinoLat"]?.toDouble() ?? 0,
    destinoLng: json["destinoLng"]?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "status": status,
    "idTaxista": idTaxista,
    "origen": origen,
    "destino": destino,
    "idHistorialViaje": idHistorialViaje,
    "origenLat": origenLat,
    "origenLng": origenLng,
    "destinoLat": destinoLat,
    "destinoLng": destinoLng,
  };
}
