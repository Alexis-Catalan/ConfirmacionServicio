import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:radio_taxi_alfa_app/src/pages/taxista/solicitud_viaje/taxista_solicitud_viaje_controlador.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;
import 'package:radio_taxi_alfa_app/src/widgets/button_app.dart';

class TaxistaSolicitudViajePage extends StatefulWidget {

  @override
  _TaxistaSolicitudViajePageState createState() => _TaxistaSolicitudViajePageState();
}

class _TaxistaSolicitudViajePageState extends State<TaxistaSolicitudViajePage> {

  TaxistaSolicitudViajeControlador _con = new TaxistaSolicitudViajeControlador();

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
    print('SE EJECUTO EL DISPOSE TAXISTA SOLICITUD VIAJE');
    _con.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _bannerClienteInfo(),
          _txtDirecciones(_con.origen ?? 'Direccción de Origen', _con.destino ?? 'Direccción de Destino'),
          _txtTeporizador()
        ],
      ),
      bottomNavigationBar: _btnAcciones(),
    );
  }

  Widget _bannerClienteInfo() {
    return ClipPath(
      clipper: WaveClipperOne(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        width: double.infinity,
        color: utils.Colors.temaColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _con.cliente?.imagen != null
                  ? NetworkImage(_con.cliente?.imagen)
                  : AssetImage('assets/img/profile.jpg'),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              child: Text(
                _con.cliente?.nombreUsuario?? 'Nombre Cliente',
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

  Widget _txtDirecciones(String origen, String destino) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Recoger en:',
            style: TextStyle(
                fontSize: 20,color: utils.Colors.origen,fontWeight: FontWeight.bold
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 20, top: 5 , right: 20, bottom: 0),
            child: Text(
              origen,
              style: TextStyle(
                  fontSize: 17
              ),
              maxLines: 2,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'LLevar a:',
            style: TextStyle(
                fontSize: 20,color: utils.Colors.destino,fontWeight: FontWeight.bold
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 20, top: 5 , right: 20, bottom: 0),
            child: Text(
              destino,
              style: TextStyle(
                  fontSize: 17
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _txtTeporizador() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 30),
      child: Text(
        _con.seconds.toString(),
        style: TextStyle(
            fontSize: 50
        ),
      ),
    );
  }

  Widget _btnAcciones() {
    return Container(
      height: 50,
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.45,
            child: ButtonApp(
              onPressed: _con.CancelarViaje,
              text: 'Cancelar',
              color: utils.Colors.conRojo,
              textColor: Colors.white,
              icon: Icons.cancel_outlined,
              iconColor: utils.Colors.conRojo,
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.45,
            child: ButtonApp(
              onPressed: _con.AceptarViaje,
              text: 'Aceptar',
              color: utils.Colors.conVerde,
              textColor: Colors.white,
              icon: Icons.check,
            ),
          ),
        ],
      ),
    );
  }

  void refresh(){
    setState(() {
    });
  }
}
