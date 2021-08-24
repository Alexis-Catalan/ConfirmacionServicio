import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:radio_taxi_alfa_app/src/api/environment.dart';
import 'package:radio_taxi_alfa_app/src/models/informacion_viaje.dart';
import 'package:radio_taxi_alfa_app/src/models/taxista.dart';
import 'package:radio_taxi_alfa_app/src/providers/auth_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/geofire_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/informacion_viaje_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/taxista_provider.dart';
import 'package:radio_taxi_alfa_app/src/widgets/bottom_sheet_cliente_info.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;

class ClienteMapaViajeControlador {
  BuildContext context;
  Function refresh;
  GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _mapController = Completer();

  CameraPosition initialPosition = CameraPosition(
      target: LatLng(1.2342774, -77.2645446),
      zoom: 14.0
  );

  Map<MarkerId, Marker> marcadores = <MarkerId, Marker>{};

  BitmapDescriptor marcadorTaxista;
  BitmapDescriptor origenMarcador;
  BitmapDescriptor destinoMarcador;

  AuthProvider _authProvider;
  TaxistaProvider _taxistaProvider;
  InformacionViajeProvider _informacionViajeProvider;
  GeofireProvider _geofireProvider;

  Set<Polyline> polylines = {};
  List<LatLng> points = new List();

  Taxista taxista;
  LatLng _taxistaLatLng;
  InformacionViaje informacionViaje;

  bool isRouteReady = false;

  String statusActual = 'Status Viaje';
  Color statusColor = utils.Colors.temaColor;

  bool isPickupTravel = false;
  bool isStartTravel = false;
  bool isFinishTravel = false;

  StreamSubscription<DocumentSnapshot> _streamUbicacionController;
  StreamSubscription<DocumentSnapshot> _streamViajeController;

  Future init(BuildContext context, Function refresh) async {
    print('Se ejecuto Cliente Mapa Viaje Controlador');
    this.context = context;
    this.refresh = refresh;
    _authProvider = new AuthProvider();
    _taxistaProvider = new TaxistaProvider();
    _informacionViajeProvider = new InformacionViajeProvider();
    _geofireProvider = new GeofireProvider();

    marcadorTaxista = await crearMarcadorImagen('assets/img/icon_taxi.png');
    origenMarcador = await crearMarcadorImagen('assets/img/map_pin_blue.png');
    destinoMarcador = await crearMarcadorImagen('assets/img/map_pin_red.png');
  }

  void openBottomSheet() {
    if (taxista == null) return;

    showMaterialModalBottomSheet(
        context: context,
        builder: (context) => BottomSheetClienteInfo(
          imageUrl: taxista?.imagen,
          username: taxista?.nombreUsuario,
          email: taxista?.correo,
          plate: taxista?.placas,
        )
    );
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
    _obtenerInfoViaje();
  }

  void dispose() {
    _streamUbicacionController?.cancel();
    _streamViajeController?.cancel();
  }


  void _obtenerInfoViaje() async {
    informacionViaje = await _informacionViajeProvider.obtenerId(_authProvider.obtenerUsuario().uid);
    animarCamaraPosicion(informacionViaje.origenLat, informacionViaje.origenLng);
    obtenerInfoTaxista(informacionViaje.idTaxista);
    obtenerUbicacionTaxista(informacionViaje.idTaxista);
  }

  void obtenerInfoTaxista(String id) async {
    taxista = await _taxistaProvider.obtenerId(id);
    refresh();
  }

  void obtenerUbicacionTaxista(String idTaxista) {
    Stream<DocumentSnapshot> stream = _geofireProvider.obtenerUbicacionIdStream(idTaxista);
    _streamUbicacionController = stream.listen((DocumentSnapshot document) {
      GeoPoint geoPoint = document.data()['posicion']['geopoint'];
      _taxistaLatLng = new LatLng(geoPoint.latitude, geoPoint.longitude);

      agregarSimpleMarcador('taxista', _taxistaLatLng.latitude, _taxistaLatLng.longitude, 'Tu taxista', '', marcadorTaxista);

      refresh();

      if (!isRouteReady) {
        isRouteReady = true;
        checkStatusViaje();
      }

    });
  }

  void checkStatusViaje() async {
    Stream<DocumentSnapshot> stream = _informacionViajeProvider.obtenerIdStream(_authProvider.obtenerUsuario().uid);
    _streamViajeController = stream.listen((DocumentSnapshot document) {
      informacionViaje = InformacionViaje.fromJson(document.data());

      if (informacionViaje.status == 'aceptado') {
        statusActual = 'Viaje Aceptado';
        statusColor = utils.Colors.temaColor;
        aceptadoViaje();
      }
      else if (informacionViaje.status == 'iniciado') {
        statusActual = 'Viaje Iniciado';
        statusColor = Colors.amber;
        inciarViaje();
      }
      else if (informacionViaje.status == 'finalizado') {
        statusActual = 'Viaje Finalizado';
        statusColor = utils.Colors.Azul;
        finalizarViaje();
      }

      refresh();

    });
  }

  void aceptadoViaje() {
    if (!isPickupTravel) {
      isPickupTravel = true;
      LatLng origen = new LatLng(_taxistaLatLng.latitude, _taxistaLatLng.longitude);
      LatLng destino = new LatLng(informacionViaje.origenLat, informacionViaje.origenLng);
      agregarSimpleMarcador('origen', destino.latitude, destino.longitude, 'Recoger aqui', '', origenMarcador);
      setPolylines(origen, destino);
    }
  }

  void inciarViaje() {
    if (!isStartTravel) {
      isStartTravel = true;
      polylines = {};
      points = List();
      marcadores.removeWhere((key, marker) => marker.markerId.value == 'origen');
      agregarSimpleMarcador(
          'destino',
          informacionViaje.destinoLat,
          informacionViaje.destinoLng,
          'Destino',
          '',
          destinoMarcador
      );

      LatLng origen = new LatLng(_taxistaLatLng.latitude, _taxistaLatLng.longitude);
      LatLng destino = new LatLng(informacionViaje.destinoLat, informacionViaje.destinoLng);

      setPolylines(origen, destino);
      refresh();
    }
  }

  void finalizarViaje() {
    if (!isFinishTravel) {
      isFinishTravel = true;
      Navigator.pushNamedAndRemoveUntil(context, 'cliente/calificacion/viaje', (route) => false, arguments: informacionViaje.idHistorialViaje);
    }
  }

  Future<void> setPolylines(LatLng origen, LatLng destino) async {
    PointLatLng pointOrigenLatLng = PointLatLng(origen.latitude, origen.longitude);
    PointLatLng pointDestinoLatLng = PointLatLng(destino.latitude, destino.longitude);

    PolylineResult result = await PolylinePoints().getRouteBetweenCoordinates(
        Environment.API_KEY_MAPS,
        pointOrigenLatLng,
        pointDestinoLatLng
    );

    for (PointLatLng point in result.points) {
      points.add(LatLng(point.latitude, point.longitude));
    }

    Polyline polyline = Polyline(
        polylineId: PolylineId('poly'),
        color: utils.Colors.temaColor,
        points: points,
        width: 6
    );
    polylines.add(polyline);
    refresh();
  }

  Future animarCamaraPosicion(double latitude, double longitude) async {
    GoogleMapController controller = await _mapController.future;
    if (controller != null) {
      controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              bearing: 0,
              target: LatLng(latitude, longitude),
              zoom: 16.8
          )
      ));
    }
  }

  Future<BitmapDescriptor> crearMarcadorImagen(String path) async {
    ImageConfiguration configuration = ImageConfiguration();
    BitmapDescriptor bitmapDescriptor =
    await BitmapDescriptor.fromAssetImage(configuration, path);
    return bitmapDescriptor;
  }


  void agregarSimpleMarcador(
      String markerId,
      double lat,
      double lng,
      String title,
      String content,
      BitmapDescriptor iconMarker
      ) {

    MarkerId id = MarkerId(markerId);
    Marker marcador = Marker(
      markerId: id,
      icon: iconMarker,
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: title, snippet: content),
    );

    marcadores[id] = marcador;
  }

}