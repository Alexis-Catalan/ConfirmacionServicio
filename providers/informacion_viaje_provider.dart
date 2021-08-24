

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:radio_taxi_alfa_app/src/models/informacion_viaje.dart';

class InformacionViajeProvider {

  CollectionReference _ref;

  InformacionViajeProvider(){
    _ref = FirebaseFirestore.instance.collection('InformacionViaje');
  }

  Future<void> crear(InformacionViaje informacionViaje) {
    String errorMessage;

    try {
      return _ref.doc(informacionViaje.id).set(informacionViaje.toJson());
    } catch(error) {
      print('Error de Registro Información Viaje: ${error.code} \n ${error.message}');
      errorMessage = error.code;
    }

    if (errorMessage != null) {
      return Future.error(errorMessage);
    }
  }

  Future<void> actualizar(Map<String, dynamic> data, String id) {
    return _ref.doc(id).update(data);
  }

  Future<InformacionViaje> obtenerId(String id) async {
    DocumentSnapshot document = await _ref.doc(id).get();

    if (document.exists) {
      InformacionViaje informacionViaje = InformacionViaje.fromJson(document.data());
      return informacionViaje;
    }

    return null;
  }

  Stream<DocumentSnapshot> obtenerIdStream(String id) {
    return _ref.doc(id).snapshots(includeMetadataChanges: true);
  }

}