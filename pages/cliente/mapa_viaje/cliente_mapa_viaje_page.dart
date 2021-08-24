import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/pages/cliente/mapa_viaje/cliente_mapa_viaje_controlador.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;

class ClienteMapaViajePage extends StatefulWidget {

  @override
  _ClienteMapaViajePageState createState() => _ClienteMapaViajePageState();
}

class _ClienteMapaViajePageState extends State<ClienteMapaViajePage> {

  ClienteMapaViajeControlador _con = ClienteMapaViajeControlador();

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
    print('SE EJECUTO EL DISPOSE MAPA VIAJE CLIENTE');
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _btnInfoTaxista(),
                    _cardStatusInfo(_con.statusActual)
                  ],
                ),
                Expanded(child: Container()),
              ],
            ),
          )
        ],
      ),
    );
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

  Widget _btnInfoTaxista() {
    return GestureDetector(
      onTap: _con.openBottomSheet,
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

  Widget _cardStatusInfo(String status) {
    return SafeArea(
        child: Container(
          width: 120,
          padding: EdgeInsets.symmetric(vertical: 10),
          margin: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
              color: _con.statusColor,
              borderRadius: BorderRadius.all(Radius.circular(20))
          ),
          child: Text(
            '${status ?? ''}',
            maxLines: 1,
            textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white
              )
          ),
        )
    );
  }

  void refresh() {
    setState(() {});
  }
}
