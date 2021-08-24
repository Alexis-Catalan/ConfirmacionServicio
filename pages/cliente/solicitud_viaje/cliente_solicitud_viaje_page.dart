import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:lottie/lottie.dart';
import 'package:radio_taxi_alfa_app/src/pages/cliente/solicitud_viaje/cliente_solicitud_viaje_controlador.dart';
import 'package:radio_taxi_alfa_app/src/widgets/button_app.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;

class ClienteSolicitudViajePage extends StatefulWidget {
  @override
  _ClienteSolicitudViajePageState createState() => _ClienteSolicitudViajePageState();
}

class _ClienteSolicitudViajePageState extends State<ClienteSolicitudViajePage> {

  ClienteSolicitudViajeControlador _con = new ClienteSolicitudViajeControlador();
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
    print('SE EJECUTO EL DISPOSE ClIENTE SOLICITUD VIAJE');
    _con.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _con.key,
      body: Column(
        children: [
          _taxistaInfo(),
          _lottieAnimation(),
          _txtBuscador(),
          _txtContador(),
        ],
      ),
      bottomNavigationBar: _btnCancelar(),
    );
  }

  Widget _taxistaInfo() {
    return ClipPath(
      clipper: WaveClipperOne(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        color: utils.Colors.temaColor,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _con.taxista?.imagen != null
                  ? NetworkImage(_con.taxista?.imagen)
                  : AssetImage('assets/img/profile.jpg'),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                  _con.taxista?.nombreUsuario ?? 'Nombre Taxista',
                maxLines: 1,
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.white
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _lottieAnimation() {
    return Lottie.asset(
        'assets/json/car-control.json',
        width: MediaQuery.of(context).size.width * 0.70,
        height: MediaQuery.of(context).size.height * 0.35,
        fit: BoxFit.fill
    );
  }

  Widget _txtBuscador() {
    return Container(
      child: Text(
        'Buscando taxistas',
        style: TextStyle(
            fontSize: 16
        ),
      ),
    );
  }

  Widget _txtContador() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 30),
      child: Text( _con.taxistas?.toString() ??
        '0',
        style: TextStyle(fontSize: 30),
      ),
    );
  }

  Widget _btnCancelar() {
    return Container(
      height: 48,
      margin: EdgeInsets.all(30),
      child: ButtonApp(
        onPressed: _con.CancelarViaje,
        text: 'Cancelar viaje',
        color: Colors.amber,
        icon: Icons.cancel_outlined,
        textColor: Colors.black,
        iconColor: Colors.amber,
      ),
    );
  }


  void refresh() {
    setState(() {});
  }
}
