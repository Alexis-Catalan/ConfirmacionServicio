import 'package:flutter/material.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;

class BottomSheetTaxistaInfo extends StatefulWidget {

  String imageUrl;
  String username;
  String email;

  BottomSheetTaxistaInfo({
     @required this.imageUrl,
     @required this.username,
    @required this.email,
  });

  @override
  _BottomSheetTaxistaInfoState createState() => _BottomSheetTaxistaInfoState();
}

class _BottomSheetTaxistaInfoState extends State<BottomSheetTaxistaInfo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      margin: EdgeInsets.all(30),
      child: Column(
        children: [
          Text(
            'Tu Cliente',
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
              widget.username ?? 'Nombre cliente',
              style: TextStyle(fontSize: 15),
            ),
            leading: Icon(Icons.person, color: utils.Colors.temaColor,),
          ),
          ListTile(
            title: Text(
              'Correo electrónico',
              style: TextStyle(fontSize: 15),
            ),
            subtitle: Text(
              widget.email ?? 'correo@domino.com',
              style: TextStyle(fontSize: 15),
            ),
            leading: Icon(Icons.email, color: utils.Colors.temaColor),
          ),
        ],
      ),
    );
  }
}
