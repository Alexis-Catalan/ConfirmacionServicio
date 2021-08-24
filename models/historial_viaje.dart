import 'dart:convert';

HistorialViaje historialViajeFromJson(String str) =>
    HistorialViaje.fromJson(json.decode(str));

String historialViajeToJson(HistorialViaje data) => json.encode(data.toJson());

class HistorialViaje {
  String id;
  String idCliente;
  String idTaxista;
  String origen;
  String destino;
  double origenLat;
  double origenLng;
  double destinoLat;
  double destinoLng;
  String nombreCliente;
  String nombreTaxista;
  double distancia;
  String duracion;
  int timestamp;
  double calificacionCliente;
  double calificacionTaxista;

  HistorialViaje({
    this.id,
    this.idCliente,
    this.idTaxista,
    this.origen,
    this.destino,
    this.origenLat,
    this.origenLng,
    this.destinoLat,
    this.destinoLng,
    this.nombreCliente,
    this.nombreTaxista,
    this.distancia,
    this.duracion,
    this.timestamp,
    this.calificacionCliente,
    this.calificacionTaxista
  });

  factory HistorialViaje.fromJson(Map<String, dynamic> json) =>
      HistorialViaje(
          id: json["id"],
          idCliente: json["idCliente"],
          idTaxista: json["idTaxista"],
          origen: json["origen"],
          destino: json["destino"],
          origenLat: json["origenLat"]?.toDouble() ?? 0,
          origenLng: json["origenLng"]?.toDouble() ?? 0,
          destinoLat: json["destinoLat"]?.toDouble() ?? 0,
          destinoLng: json["destinoLng"]?.toDouble() ?? 0,
          nombreCliente: json["nombreCliente"],
          nombreTaxista: json["nombreTaxista"],
          distancia: json["distancia"]?.toDouble() ?? 0,
          duracion: json["duracion"],
          timestamp: json["timestamp"],
          calificacionCliente: json["calificacionCliente"]?.toDouble() ?? 0,
          calificacionTaxista: json["calificacionTaxista"]?.toDouble() ?? 0
      );

  Map<String, dynamic> toJson() =>
      {
        "id": id,
        "idCliente": idCliente,
        "idTaxista": idTaxista,
        "origen": origen,
        "destino": destino,
        "origenLat": origenLat,
        "origenLng": origenLng,
        "destinoLat": destinoLat,
        "destinoLng": destinoLng,
        "nombreCliente": nombreCliente,
        "nombreTaxista": nombreTaxista,
        "distancia": distancia,
        "duracion": duracion,
        "timestamp": timestamp,
        "calificacionCliente": calificacionCliente,
        "calificacionTaxista": calificacionTaxista
      };
}
