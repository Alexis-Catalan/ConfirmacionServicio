import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:radio_taxi_alfa_app/src/models/cliente.dart';
import 'package:radio_taxi_alfa_app/src/models/informacion_viaje.dart';
import 'package:radio_taxi_alfa_app/src/providers/auth_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/cliente_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/geofire_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/informacion_viaje_provider.dart';
import 'package:radio_taxi_alfa_app/src/utils/shared_pref.dart';
import 'package:radio_taxi_alfa_app/src/utils/snackbar.dart' as utils;

class TaxistaSolicitudViajeControlador {

  BuildContext context;
  Function refresh;
  GlobalKey<ScaffoldState> key = new GlobalKey();

  SharedPref _sharedPref;

  String origen;
  String destino;
  String idCliente;
  Cliente cliente;

  ClienteProvider _clienteProvider;
  InformacionViajeProvider _informacionViajeProvider;
  AuthProvider _authProvider;
  GeofireProvider _geofireProvider;

  Timer _timer;
  int seconds = 30;

  StreamSubscription<DocumentSnapshot> _streamStatusSubscription;


  Future init (BuildContext context, Function refresh) {
    print('Se Inicio Taxista Solicitud Viaje Controlador');
    this.context = context;
    this.refresh = refresh;
    _sharedPref = new SharedPref();
    _sharedPref.guardar('esNotificacion', 'false');

    _clienteProvider = new ClienteProvider();
    _informacionViajeProvider = new InformacionViajeProvider();
    _authProvider = new AuthProvider();
    _geofireProvider = new GeofireProvider();

    Map<String, dynamic> arguments = ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    origen = arguments['origin'];
    destino = arguments['destination'];
    idCliente = arguments['idClient'];

    getClienteInfo();
    iniciarTemporizador();
    _comprobarRespuestaCliente();
  }

  void getClienteInfo() async {
    cliente = await _clienteProvider.obtenerId(idCliente);
    print('Client: ${cliente.toJson()}');
    refresh();
  }


  void dispose () {
    _timer?.cancel();
    _streamStatusSubscription?.cancel();
  }

  void iniciarTemporizador() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      seconds = seconds - 1;
      refresh();
      if (seconds == 0) {
        CancelarViaje();
      }
    });
  }

  void AceptarViaje() {
    Map<String, dynamic> data = {
      'idTaxista': _authProvider.obtenerUsuario().uid,
      'status': 'aceptado'
    };

    _timer?.cancel();

    _informacionViajeProvider.actualizar(data, idCliente);
    _geofireProvider.eliminarUbicacion(_authProvider.obtenerUsuario().uid);
    Navigator.pushNamedAndRemoveUntil(context, 'taxista/mapa/viaje', (route) => false, arguments: idCliente);
    // Navigator.pushReplacementNamed(context, 'driver/travel/map', arguments: idClient);
  }

  void CancelarViaje() {
    Map<String, dynamic> data = {
      'status': 'no_aceptado'
    };
    _timer?.cancel();
    _informacionViajeProvider.actualizar(data, idCliente);
    Navigator.pushNamedAndRemoveUntil(context, 'taxista/mapa', (route) => false);
  }

  void _comprobarRespuestaCliente() {
    Stream<DocumentSnapshot> stream = _informacionViajeProvider.obtenerIdStream(idCliente);
    _streamStatusSubscription = stream.listen((DocumentSnapshot document) {
      InformacionViaje informacionViaje = InformacionViaje.fromJson(document.data());

      if (informacionViaje.status == 'cancelado') {
          utils.Snackbar.showSnackbar(context, key, Colors.red, 'El cliente a cancelado el viaje.');
          Navigator.pushNamedAndRemoveUntil(context, 'taxista/mapa', (route) => false);
      }
    });
  }

}