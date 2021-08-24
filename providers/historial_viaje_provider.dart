import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:radio_taxi_alfa_app/src/models/cliente.dart';
import 'package:radio_taxi_alfa_app/src/models/historial_viaje.dart';
import 'package:radio_taxi_alfa_app/src/models/taxista.dart';
import 'package:radio_taxi_alfa_app/src/providers/taxista_provider.dart';

import 'cliente_provider.dart';

class HistorialViajeProvider {

  CollectionReference _ref;

  HistorialViajeProvider() {
    _ref = FirebaseFirestore.instance.collection('HistorialViajes');
  }

  Future<String> crear(HistorialViaje historialViaje) async {
    String errorMessage;

    try {
      String id = _ref.doc().id;
      historialViaje.id = id;

      await _ref.doc(historialViaje.id).set(historialViaje.toJson());
      return id;
    } catch(error) {
      print('Error de Registro Historial Viaje: ${error.code} \n ${error.message}');
      errorMessage = error.code;
    }

    if (errorMessage != null) {
      return Future.error(errorMessage);
    }
  }

  Future<HistorialViaje> obtenerId(String id) async {
    DocumentSnapshot document = await _ref.doc(id).get();

    if (document.exists) {
      HistorialViaje historialViaje = HistorialViaje.fromJson(document.data());
      return historialViaje;
    }

    return null;
  }

  Future<void> actualizar(Map<String, dynamic> data, String id) {
    return _ref.doc(id).update(data);
  }

  Future<List<HistorialViaje>> obtenerIdCliente(String idCliente) async {
    QuerySnapshot querySnapshot = await _ref.where('idCliente', isEqualTo: idCliente).orderBy('timestamp', descending: true).get();
    List<Map<String, dynamic>> allData = querySnapshot.docs.map((doc) => doc.data()).toList();

    List<HistorialViaje> historialViajeList = new List();

    for (Map<String, dynamic> data in allData) {
      historialViajeList.add(HistorialViaje.fromJson(data));
    }

    for (HistorialViaje historialViaje in historialViajeList) {
      TaxistaProvider taxistaProvider = new TaxistaProvider();
      Taxista taxista = await taxistaProvider.obtenerId(historialViaje.idTaxista);
      historialViaje.nombreTaxista = taxista.nombreUsuario;
    }

    return historialViajeList;
  }

  Future<List<HistorialViaje>> obtenerIdTaxista(String idTaxista) async {
    QuerySnapshot querySnapshot = await _ref.where('idTaxista', isEqualTo: idTaxista).orderBy('timestamp', descending: true).get();
    List<Map<String, dynamic>> allData = querySnapshot.docs.map((doc) => doc.data()).toList();

    List<HistorialViaje> historialViajeList = new List();

    for (Map<String, dynamic> data in allData) {
      historialViajeList.add(HistorialViaje.fromJson(data));
    }

    for (HistorialViaje historialViaje in historialViajeList) {
      ClienteProvider clienteProvider = new ClienteProvider();
      Cliente cliente = await clienteProvider.obtenerId(historialViaje.idCliente);
      historialViaje.nombreCliente = cliente.nombreUsuario;
    }

    return historialViajeList;
  }

  Future<List<HistorialViaje>> getAll() async {
    QuerySnapshot querySnapshot = await _ref.orderBy('timestamp', descending: true).get();
    List<Map<String, dynamic>> allData = querySnapshot.docs.map((doc) => doc.data()).toList();

    List<HistorialViaje> historialViajeList = new List();

    for (Map<String, dynamic> data in allData) {
      historialViajeList.add(HistorialViaje.fromJson(data));
    }

    return historialViajeList;
  }

}