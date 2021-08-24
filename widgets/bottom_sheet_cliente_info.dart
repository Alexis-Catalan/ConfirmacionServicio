import 'package:flutter/material.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;

class BottomSheetClienteInfo extends StatefulWidget {

  String imageUrl;
  String username;
  String email;
  String plate;

  BottomSheetClienteInfo({
     @required this.imageUrl,
     @required this.username,
    @required this.email,
     @required this.plate,
  });

  @override
  _BottomSheetClienteInfoState createState() => _BottomSheetClienteInfoState();
}

class _BottomSheetClienteInfoState extends State<BottomSheetClienteInfo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      margin: EdgeInsets.all(30),
      child: Column(
        children: [
          Text(
            'Tu Taxista',
            style: TextStyle(
              fontSize: 18
            ),
          ),
          SizedBox(height: 15),
          CircleAvatar(
            backgroundImage: widget.imageUrl != null
                ? NetworkImage(widget.imageUrl)
                : AssetImage('assets/img/profile.jpg'),
            radius: 50,
          ),
          ListTile(
            title: Text(
              'Nombre',
              style: TextStyle(fontSize: 15),
            ),
            subtitle: Text(
              widget.username ?? 'Nombre taxista',
              style: TextStyle(fontSize: 15),
            ),
            leading: Icon(Icons.person,color: utils.Colors.temaColor,),
          ),
          ListTile(
            title: Text(
              'Correo electrónico',
              style: TextStyle(fontSize: 15),
            ),
            subtitle: Text(
              widget.email ?? 'correo@dominio.com',
              style: TextStyle(fontSize: 15),
            ),
            leading: Icon(Icons.email, color: utils.Colors.temaColor,),
          ),
          ListTile(
            title: Text(
              'Placa del vehiculo',
              style: TextStyle(fontSize: 15),
            ),
            subtitle: Text(
              widget.plate ?? 'AAA-123-A',
              style: TextStyle(fontSize: 15),
            ),
            leading: Icon(Icons.directions_car_rounded, color: utils.Colors.temaColor,),
          ),
        ],
      ),
    );
  }
}
