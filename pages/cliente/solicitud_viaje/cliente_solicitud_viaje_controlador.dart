import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/models/informacion_viaje.dart';
import 'package:radio_taxi_alfa_app/src/models/taxista.dart';
import 'package:radio_taxi_alfa_app/src/providers/auth_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/geofire_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/informacion_viaje_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/push_notificaciones_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/taxista_provider.dart';
import 'package:radio_taxi_alfa_app/src/utils/snackbar.dart' as utils;

class ClienteSolicitudViajeControlador {

  BuildContext context;
  Function refresh;
  GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();

  int taxistas;

  String origen;
  String destino;
  LatLng origenLatLng;
  LatLng destinoLatLng;

  InformacionViajeProvider _informacionViajeProvider;
  AuthProvider _authProvider;
  GeofireProvider _geofireProvider;
  TaxistaProvider _taxistaProvider;
  PushNotificacionesProvider _pushNotificacionesProvider;

  Taxista taxista;

  List<String> listaTaxistas = new List();

  StreamSubscription<List<DocumentSnapshot>> _streamSubscription;
  StreamSubscription<DocumentSnapshot> _streamStatusSubscription;

  Future init(BuildContext context, Function refresh) {
    print('Se Inicio Cliente Solicitud Viaje Controlador');
    this.context = context;
    this.refresh = refresh;
    _informacionViajeProvider = new InformacionViajeProvider();
    _authProvider = new AuthProvider();
    _geofireProvider = new GeofireProvider();
    _taxistaProvider = new TaxistaProvider();
    _pushNotificacionesProvider = new PushNotificacionesProvider();
    Map<String, dynamic> arguments = ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    origen = arguments['origen'];
    destino = arguments['destino'];
    origenLatLng = arguments['origenLatLng'];
    destinoLatLng = arguments['destinoLatLng'];

    _crearInformacionViaje();
    _getTaxistasCercanos();
  }

  void _crearInformacionViaje() async {
    InformacionViaje informacionViaje = new InformacionViaje(
        id: _authProvider.obtenerUsuario().uid,
        origen: origen,
        destino: destino,
        origenLat: origenLatLng.latitude,
        origenLng: origenLatLng.longitude,
        destinoLat: destinoLatLng.latitude,
        destinoLng: destinoLatLng.longitude,
        status: 'creado'
    );

    await _informacionViajeProvider.crear(informacionViaje);
    _comprobarRespuestaTaxista();
  }

  void dispose () {
    _streamSubscription?.cancel();
    _streamStatusSubscription?.cancel();
  }

  void _comprobarRespuestaTaxista() {
    Stream<DocumentSnapshot> stream = _informacionViajeProvider.obtenerIdStream(_authProvider.obtenerUsuario().uid);
    _streamStatusSubscription = stream.listen((DocumentSnapshot document) {
      InformacionViaje informacionViaje = InformacionViaje.fromJson(document.data());

      if (informacionViaje.idTaxista != null && informacionViaje.status == 'aceptado') {
        Navigator.pushNamedAndRemoveUntil(context, 'cliente/mapa/viaje', (route) => false);
      }
      else if (informacionViaje.status == 'no_aceptado') {
        listaTaxistas.removeAt(0);
        if(listaTaxistas.length == 0) {
          utils.Snackbar.showSnackbar(context, key, Colors.red, 'El taxista no acepto tu solicitud.');
          Future.delayed(Duration(milliseconds: 2000), () {
            Navigator.pushNamedAndRemoveUntil(
                context, 'cliente/mapa', (route) => false);
          });
        }else {
          utils.Snackbar.showSnackbar(context, key, Colors.red, 'El taxista no acepto tu solicitud se ha enviado otra notificacion a otro taxista.');
          getTaxistaInfo(listaTaxistas[0]);
        }
      } else if (informacionViaje.status == 'cancelado'){
        utils.Snackbar.showSnackbar(context, key, Colors.red, 'Has cancelado el viaje.');
      }

    });
  }

  void _getTaxistasCercanos() {
    Stream<List<DocumentSnapshot>> stream = _geofireProvider.obtenerTaxistasCercanos(
        origenLatLng.latitude,
        origenLatLng.longitude,
        1
    );

    _streamSubscription = stream.listen((List<DocumentSnapshot> documentList) {
      for (DocumentSnapshot d in documentList) {
        print('CONDUCTOR ENCONTRADO ${d.id}');
        listaTaxistas.add(d.id);
        print(listaTaxistas.length);
        taxistas = listaTaxistas.length;
        refresh();
      }

      getTaxistaInfo(listaTaxistas[0]);
      _streamSubscription?.cancel();
    });
  }

  Future<void> getTaxistaInfo(String idTaxista) async {
    taxista = await _taxistaProvider.obtenerId(idTaxista);
    refresh();
    _enviarNotificacion(taxista.token);
  }

  void _enviarNotificacion(String token) {
    print('TOKEN: $token');

    Map<String, dynamic> data = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'idClient': _authProvider.obtenerUsuario().uid,
      'origin': origen,
      'destination': destino,
    };
    _pushNotificacionesProvider.enviarMensaje(token, data, 'Solicitud de servicio', 'Un cliente esta solicitando un viaje');
  }


  void CancelarViaje() {
    Map<String, dynamic> data = {
      'status': 'cancelado'
    };
    _informacionViajeProvider.actualizar(data, _authProvider.obtenerUsuario().uid);
    Navigator.pushNamedAndRemoveUntil(context, 'cliente/mapa', (route) => false);
  }

}