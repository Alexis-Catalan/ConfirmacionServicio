import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:radio_taxi_alfa_app/src/api/environment.dart';
import 'package:radio_taxi_alfa_app/src/models/cliente.dart';
import 'package:radio_taxi_alfa_app/src/models/historial_viaje.dart';
import 'package:radio_taxi_alfa_app/src/models/informacion_viaje.dart';
import 'package:radio_taxi_alfa_app/src/models/taxista.dart';
import 'package:radio_taxi_alfa_app/src/providers/auth_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/cliente_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/geofire_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/historial_viaje_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/informacion_viaje_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/taxista_provider.dart';
import 'package:radio_taxi_alfa_app/src/utils/my_progress_dialog.dart';
import 'package:radio_taxi_alfa_app/src/utils/snackbar.dart' as utils;
import 'package:location/location.dart' as ubicacion;
import 'package:radio_taxi_alfa_app/src/widgets/bottom_sheet_taxista_info.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;

class TaxistaMapaViajeControlador {

  BuildContext context;
  Function refresh;
  GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _mapController = Completer();

  CameraPosition initialPosition = CameraPosition(
      target: LatLng(17.5694024, -99.5181556), zoom: 14.0);


  Map<MarkerId, Marker> marcadores = <MarkerId, Marker>{};

  Position _posicion;
  StreamSubscription<Position> _posicionStream;

  BitmapDescriptor marcadorTaxista;
  BitmapDescriptor origenMarcador;
  BitmapDescriptor destinoMarcador;

  AuthProvider _authProvider;
  TaxistaProvider _taxistaProvider;
  ClienteProvider _clienteProvider;
  GeofireProvider _geofireProvider;
  InformacionViajeProvider _informacionViajeProvider;
  HistorialViajeProvider _historialViajeProvider;

  ProgressDialog _progressDialog;

  StreamSubscription<DocumentSnapshot> _taxistaInfoSuscription;

  Set<Polyline> polylines = {};
  List<LatLng> points = new List();

  Taxista taxista;
  Cliente _cliente;

  String _idViaje;
  InformacionViaje informacionViaje;

  String statusActual = 'INICIAR VIAJE';
  Color statusColor = utils.Colors.conVerde;
  IconData statusIcono =  Icons.play_arrow;

  double _distanceBetweenO;
  double _distanceBetweenD;

  Timer _timer;
  String tiempo = '0 seg';
  int seconds = 0;
  int aux = 60;
  int minutos = 0;
  double mt = 0;
  double km = 0;

  Future init(BuildContext context, Function refresh) async {
    print('Se Ejecuto Taxista Mapa Viaje Controlador');
    this.context = context;
    this.refresh = refresh;

    _idViaje = ModalRoute.of(context).settings.arguments as String;

    _authProvider = new AuthProvider();
    _taxistaProvider = new TaxistaProvider();
    _clienteProvider = new ClienteProvider();
    _geofireProvider = new GeofireProvider();
    _informacionViajeProvider = new InformacionViajeProvider();
    _historialViajeProvider = new HistorialViajeProvider();
    _progressDialog = MyProgressDialog.createProgressDialog(context, 'Conectandose...');

    marcadorTaxista = await crearMarcadorImagen('assets/img/taxi_icon.png');
    origenMarcador = await crearMarcadorImagen('assets/img/map_pin_blue.png');
    destinoMarcador = await crearMarcadorImagen('assets/img/map_pin_red.png');

    comprobarGPS();
    obtenerInfoTaxista();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
  }

  void obtenerInfoTaxista() {
    Stream<DocumentSnapshot> taxistaStream = _taxistaProvider.obtenerIdStream(_authProvider.obtenerUsuario().uid);
    _taxistaInfoSuscription = taxistaStream.listen((DocumentSnapshot document) {
      taxista = Taxista.fromJson(document.data());
      refresh();
    });
  }

  void CentrarPosicion() {
    if (_posicion != null) {
      animarCamaraPosicion(_posicion.latitude, _posicion.longitude);
    } else {
      utils.Snackbar.showSnackbar(context, key,Colors.red, 'Activa el GPS para obtener la posición.');
    }
  }

  void abrirBottomSheet() {
    if (_cliente == null) return;

    showMaterialModalBottomSheet(
        context: context,
        builder: (context) => BottomSheetTaxistaInfo(
          imageUrl: _cliente?.imagen,
          username: _cliente?.nombreUsuario,
          email: _cliente?.correo,
        )
    );
  }

  void dispose() {
    _timer?.cancel();
    _posicionStream?.cancel();
    _taxistaInfoSuscription?.cancel();
  }

  void comprobarGPS() async {
    bool activoUbicacion = await Geolocator.isLocationServiceEnabled();
    if (activoUbicacion) {
      print('GPS ACTIVADO');
      actualizarUbicacion();
    } else {
      print('GPS DESACTIVADO');
      bool ubicacionGPS = await ubicacion.Location().requestService();
      if (ubicacionGPS) {
        actualizarUbicacion();
        print('ACTIVO EL GPS');
      }
    }
  }

  void _obtenerInfoViaje() async {
    informacionViaje = await _informacionViajeProvider.obtenerId(_idViaje);
    LatLng origen = new LatLng(_posicion.latitude, _posicion.longitude);
    LatLng destino = new LatLng(informacionViaje.origenLat, informacionViaje.origenLng);
    agregarSimpleMarcador('origen', destino.latitude, destino.longitude, 'Recoger aqui', '', origenMarcador);
    setPolylines(origen, destino);
    obtenerClienteInfo();
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

  void obtenerClienteInfo() async {
    _cliente = await _clienteProvider.obtenerId(_idViaje);
  }


  void guardarUbicacion() async {
    await _geofireProvider.crearTrabajando(_authProvider.obtenerUsuario().uid, _posicion.latitude, _posicion.longitude);
    _progressDialog.hide();
  }

  void cercaPosicionRecoger(LatLng origen, LatLng destino) {
    _distanceBetweenO = Geolocator.distanceBetween(
        origen.latitude,
        origen.longitude,
        destino.latitude,
        destino.longitude
    );
    print('------ DISTANCIA ORIGEN: $_distanceBetweenO--------');
  }

  void cercaPosicionFinalizar(LatLng origen, LatLng destino) {
    _distanceBetweenD = Geolocator.distanceBetween(
        origen.latitude,
        origen.longitude,
        destino.latitude,
        destino.longitude
    );
    print('------ DISTANCIA DESTINO: $_distanceBetweenD--------');
  }

  void actualizarStatus () {
    if (informacionViaje.status == 'aceptado') {
      inciarViaje();
    }
    else if (informacionViaje.status == 'iniciado') {
      finalizarViaje();
    }
  }

  void inciarViaje() async {
    if (_distanceBetweenO <= 300) {
      Map<String, dynamic> data = {
        'status': 'iniciado'
      };
      await _informacionViajeProvider.actualizar(data, _idViaje);
      informacionViaje.status = 'iniciado';
      statusActual = 'FINALIZAR VIAJE';
      statusColor = Colors.cyan;
      statusIcono = Icons.flag;

      polylines = {};
      points = List();
      // markers.remove(markers['from']);
      marcadores.removeWhere((key, marker) => marker.markerId.value == 'origen');
      agregarSimpleMarcador(
          'destino',
          informacionViaje.destinoLat,
          informacionViaje.destinoLng,
          'Destino',
          '',
          destinoMarcador
      );

      LatLng origen = new LatLng(_posicion.latitude, _posicion.longitude);
      LatLng destino = new LatLng(informacionViaje.destinoLat, informacionViaje.destinoLng);

      setPolylines(origen, destino);
      startTimer();
      refresh();
    }
    else {
      utils.Snackbar.showSnackbar(context, key, Colors.red, 'Debes estar cerca a la posicion del cliente para iniciar el viaje');
    }
    refresh();
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      seconds = timer.tick;
      print('Segundos: $seconds');
      if(seconds == aux){
        minutos++;
        aux += 60;
      }
      if(minutos == 0){
        tiempo = '$seconds seg';
      } else {
        tiempo = '$minutos min';
      }
      refresh();
    });
  }

  void finalizarViaje() async {
    if (_distanceBetweenD <= 300) {
      _timer?.cancel();
      guardarHistorialViaje();
    } else {
      utils.Snackbar.showSnackbar(context, key, Colors.red, 'Debes estar cerca a la posicion de destino para finalizar el viaje');
    }
  }

  void guardarHistorialViaje() async {
    HistorialViaje historialViaje = new HistorialViaje(
        origen: informacionViaje.origen,
        destino: informacionViaje.destino,
        origenLat: informacionViaje.origenLat,
        origenLng: informacionViaje.origenLng,
        destinoLat: informacionViaje.destinoLat,
        destinoLng: informacionViaje.destinoLng,
        idTaxista: _authProvider.obtenerUsuario().uid,
        idCliente: _idViaje,
        distancia: km,
        duracion: tiempo,
        timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    String id = await _historialViajeProvider.crear(historialViaje);

    Map<String, dynamic> data = {
      'status': 'finalizado',
      'idHistorialViaje': id,
    };
    await _informacionViajeProvider.actualizar(data, _idViaje);
    informacionViaje.status = 'finalizado';

    Navigator.pushNamedAndRemoveUntil(context, 'taxista/calificacion/viaje', (route) => false, arguments: id);
  }

  void actualizarUbicacion() async  {
    try {
      await _determinarPosicion();
      _posicion = await Geolocator.getLastKnownPosition();//Obtener la ultima posicion de la ubicación.
      _obtenerInfoViaje();
      CentrarPosicion();
      guardarUbicacion();

      agregarMarcador('Taxista', _posicion.latitude, _posicion.longitude, 'Tu posicion', taxista.nombreUsuario, marcadorTaxista);
      refresh();

      _posicionStream = Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.best, distanceFilter: 1).listen((Position position) {

        if (informacionViaje?.status == 'iniciado') {
          mt = mt + Geolocator.distanceBetween(
              _posicion.latitude,
              _posicion.longitude,
              position.latitude,
              position.longitude
          );
          km = mt / 1000;
        }

        _posicion = position;
        agregarMarcador('Taxista', _posicion.latitude, _posicion.longitude, 'Tu posicion', taxista.nombreUsuario, marcadorTaxista);
        animarCamaraPosicion(_posicion.latitude, _posicion.longitude);

        if (informacionViaje.origenLat != null && informacionViaje.origenLng != null) {
          LatLng origen = new LatLng(_posicion.latitude, _posicion.longitude);
          LatLng destino = new LatLng(informacionViaje.origenLat, informacionViaje.origenLng);
          cercaPosicionRecoger(origen, destino);
        }

        if (informacionViaje.destinoLat != null && informacionViaje.destinoLng != null) {
          LatLng origen = new LatLng(_posicion.latitude, _posicion.longitude);
          LatLng destino = new LatLng(informacionViaje.destinoLat, informacionViaje.destinoLng);
          cercaPosicionFinalizar(origen, destino);
        }

        guardarUbicacion();
        refresh();
      });
    } catch(error) {
      print('Error en la localización: $error');
    }
  }

  Future<Position> _determinarPosicion() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    return await Geolocator.getCurrentPosition();
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

  void agregarMarcador (String marcadorId, double lat, double lng, String titulo, String content, BitmapDescriptor iconMarcador) {
    MarkerId id = MarkerId(marcadorId);

    Marker marcador = Marker(
        markerId: id,
        icon: iconMarcador,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: titulo, snippet: content),
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: Offset(0.5, 0.5),
        rotation: _posicion.heading
    );

    marcadores[id] = marcador;

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