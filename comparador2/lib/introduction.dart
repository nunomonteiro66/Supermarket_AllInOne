import 'dart:io';
import 'package:comparador2/lib.dart';
import 'package:flutter/material.dart';

class introductionPage extends StatelessWidget {
  const introductionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        home: Scaffold(
            body: Center(
                child: Image(
          image: AssetImage("assets/images/intro_icon.png"),
        )))

        /*
        Column(children: [
          Container(height: 100,),
          Container(child: Text("Comparador de produtos de vários supermercados", style: TextStyle(fontSize: 30, ),),),
          Center(child: Image(image: AssetImage("assets/images/all_in_one.png"))),
        ],), */
        );
  }
}
