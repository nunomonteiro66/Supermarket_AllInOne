import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import "lib.dart";
import 'produto_window.dart';
/*
void buildNoInternetPage(context) {
  Navigator.push(
      context, MaterialPageRoute(builder: (context) => noInternetPage()));
}
*/

class noInternetPage extends StatelessWidget {
  Function reload;
  //const noInternetPage({Key? key, this.reload}) : super(key: key);

  noInternetPage(this.reload);

  @override
  Widget build(BuildContext context) {
    debugMsgDev("pagina nao internet", tag: "noInternet");
    return MaterialApp(
        title: "No conection",
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Scaffold(
          drawer: Drawer(),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image(image: AssetImage("assets/images/no_connection.jpg")),
              Align(
                alignment: Alignment.center,
                child: Center(
                  child: Text(
                    "Não foi possível obter ligação com o servidor",
                    style: TextStyle(fontSize: 30),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ElevatedButton(
                child: Text("Tentar novamente"),
                onPressed: () {
                  reload();
                },
              ),
            ],
          ),
        ));
  }
}
