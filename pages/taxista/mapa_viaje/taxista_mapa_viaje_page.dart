import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/pages/taxista/mapa_viaje/taxista_mapa_viaje_controlador.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;
import 'package:radio_taxi_alfa_app/src/widgets/button_app.dart';

class TaxistaMapaViajePage extends StatefulWidget {

  @override
  _TaxistaMapaViajePageState createState() => _TaxistaMapaViajePageState();
}

class _TaxistaMapaViajePageState extends State<TaxistaMapaViajePage> {

  TaxistaMapaViajeControlador _con = new TaxistaMapaViajeControlador();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _con.init(context, refresh);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print('SE EJECUTO EL DISPOSE MAPA VIAJE TAXISTA');
    _con.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _con.key,
        body: Stack(
          children: [
            _googleMapsWidget(),
            SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _btnInfoCliente(),
                        Column(
                          children: [
                            _cardKmInfo(_con.km?.toStringAsFixed(1)),
                            _cardMinInfo(_con.tiempo)
                          ],
                        ),
                        _btnPosicionCentral()
                      ],
                    ),
                    Expanded(child: Container()),
                    _btnStatus()
                  ],
                ))
          ],
        ));
  }

  Widget _googleMapsWidget() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _con.initialPosition,
      onMapCreated: _con.onMapCreated,
      markers: Set<Marker>.of(_con.marcadores.values),
      polylines: _con.polylines,
      mapToolbarEnabled: false,
    );
  }

  Widget _btnInfoCliente() {
    return GestureDetector(
      onTap: _con.abrirBottomSheet,
      child: Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          shape: CircleBorder(),
          color: utils.Colors.temaColor,
          elevation: 4.0,
          child: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardKmInfo(String km) {
    return SafeArea(
        child: Container(
          width: 110,
          margin: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.all(Radius.circular(20))
          ),
          child: Text(
            '${km ?? ''} km',
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        )
    );
  }


  Widget _cardMinInfo(String min) {
    return SafeArea(
        child: Container(
          width: 110,
          margin: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
              color: utils.Colors.Azul,
              borderRadius: BorderRadius.all(Radius.circular(20))
          ),
          child: Text( min,
            maxLines: 1,
            textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white
              )
          ),
        )
    );
  }


  Widget _btnPosicionCentral() {
    return GestureDetector(
      onTap: _con.CentrarPosicion,
      child: Container(
        alignment: Alignment.centerRight,
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          shape: CircleBorder(),
          color: Colors.white,
          elevation: 5.0,
          child: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.my_location,
              color: utils.Colors.azul,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _btnStatus() {
    return Container(
      height: 50,
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.symmetric(horizontal: 60, vertical: 30),
      child: ButtonApp(
        onPressed: _con.actualizarStatus,
        text: _con.statusActual,
        color: _con.statusColor,
        icon: _con.statusIcono,
        iconColor: _con.statusColor,
      ),
    );
  }

  void refresh() {
    setState(() {});
  }
}
