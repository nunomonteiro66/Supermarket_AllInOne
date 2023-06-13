// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:comparador2/lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

void func() {}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Widget myWidget() {
    return FractionallySizedBox(
      widthFactor: 0.7,
      heightFactor: 0.3,
      child: Container(
        color: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
          drawer: Drawer(),
          body: CustomScrollView(
            slivers: <Widget>[
              //-------------------------------------------------------------------TOP BAR
              SliverAppBar(
                floating: true,
                pinned: false,
                title: SearchBar(),
                actions: <Widget>[
                  //-------------------------------------------------------------------Icon Basket
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: func,
                  ),
                ],
              ),
              SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                //coluna com o titulo e o container, que vai ter os cards
                return supermarketsColumn();
              }, childCount: 1))
            ],
          ),
          bottomNavigationBar: DownBar()),
    );
  }
}

/*
class supermarketColumn extends StatefulWidget {
  const supermarketColumn({Key? key}) : super(key: key);

  @override
  State<supermarketColumn> createState() => _supermarketColumnState();
}

class _supermarketColumnState extends State<supermarketColumn> {
  Future<List> readJson() async {
    var test;
    var listProdutos = [];
    final String response =
        await rootBundle.rootBundle.loadString('assets/response.json');
    final data = await json.decode(response);

    for (int i = 0; i < data.length; i++) {
      var myData = Map<String, dynamic>.from(data[i]);
      //debugMsg(myData['nome']);
      listProdutos.add(myData);
    }

    return listProdutos;
  }

  @override
  Widget build(BuildContext context) {
    var listProdutos = readJson();
    debugMsg(listProdutos.toString());
    return Column(
      children: [
        Text("Continente"),
        Container(
            height: 200,
            width: double.infinity,
            color: Colors.red,
            child: Text("asdsa") //listViewWithCards(listProdutos[0]),
            )
      ],
    );
  }
}

*/

//column com o titulo e o container que vai conter as cards
class supermarketsColumn extends StatelessWidget {
  //const supermarketsColumn({Key? key}) : super(key: key);

  //lista com os Map's de cada produto

  var listProdutos = [];

  Future<List> readJson() async {
    var test;
    var listProdutos = [];
    final String response =
        await rootBundle.rootBundle.loadString('assets/response.json');
    final data = await json.decode(response);

    for (int i = 0; i < data.length; i++) {
      var myData = Map<String, dynamic>.from(data[i]);
      debugMsg("---------------------------------");
      //debugMsg(myData['nome']);
      listProdutos.add(myData);
    }
    debugMsg(listProdutos.length.toString());
    return listProdutos;
  }

  //list of list of maps
  //[ MapCont[mapp1, mapp2, ...], MapLidl[mapp1, mapp2, ...], ...]

  void getValues() async {
    listProdutos = await readJson();
    //todos os supermercados
    for (var j = 0; j < listProdutos.length; j++) {
      //todos os produtos
      for (var i = 0; i < listProdutos[j].length; i++) {
        this.listProdutos.add(listProdutos[i]);
      }
    }
  }

  var teste;

  @override
  Widget build(BuildContext context) {
    debugMsg(listProdutos.toString());
    return Column(
      children: [
        Text("Continente"),
        Container(
            height: 200,
            width: double.infinity,
            color: Colors.red,
            child: FutureBuilder<List<dynamic>>(
              future: readJson(),
              builder: (context, produto) {
                if (produto.hasData) {
                  return ListView.builder(
                    itemCount: produto.data?.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Container(
                          width: 170,
                          height: double.infinity,
                          color: Colors.green,
                          child: //Container(color: Colors.purple, height: 20));
                              cardsGenerator(produto.data![index]));
                    },
                  );
                }
                return Container();
              },
            )

            //listViewWithCards(listProdutos[0]),
            )
      ],
    );
  }
}

//TextField search bar
class SearchBar extends StatefulWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: 'Enter a search term',
      ),
    );
  }
}

class DownBar extends StatefulWidget {
  const DownBar({Key? key}) : super(key: key);

  @override
  State<DownBar> createState() => _DownBarState();
}

class _DownBarState extends State<DownBar> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <IconButton>[
          IconButton(iconSize: 30, onPressed: func, icon: Icon(Icons.home)),
          IconButton(iconSize: 30, onPressed: func, icon: Icon(Icons.person))
        ],
      ),
    );
  }
}

class containerGreen extends StatelessWidget {
  const containerGreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text("a"),
      decoration: BoxDecoration(color: Colors.green),
      height: 90,
    );
  }
}

//list view horizontal, dentro do container que o chama (que vai conter os cards)
class listViewWithCards extends StatelessWidget {
  //const listViewWithCards({Key? key}) : super(key: key);

  //lista com map's, sendo cada map um produto
  final listProducts;

  listViewWithCards(this.listProducts);

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (var produto in listProducts)
          Container(
              width: 170, color: Colors.green, child: cardsGenerator(produto))
      ],
    );
  }
}

//"template" para cada card , nos diversos containers dos supermercados
class cardsGenerator extends StatelessWidget {
  //const cardsGenerator({Key? key}) : super(key: key);

  //map correspondente ao produto
  final produto;

  cardsGenerator(this.produto);

  @override
  Widget build(BuildContext context) {
    return Card(
      //coluna no interior do card
      child: Column(
        children: [
          Text(produto['nome']),
          Text(produto['marca']),
          Flexible(
            child: Image.network(produto['img']),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(produto['desconto'] == 0
                  ? ""
                  : produto['desconto']['preco_original'].toString()),
              Text(produto['preco'].toString()),
              FloatingActionButton(onPressed: null)
            ],
          )
        ],
      ),
    );
  }
}

/*
Future<void> readJson() async {
    final String response =
        await rootBundle.rootBundle.loadString('assets/response.json');
    final data = await json.decode(response);

    setState(() {
      for (int i = 0; i < data.length; i++) {
        var myData = Map<String, dynamic>.from(data[i]);
        //cardProduct cp = cardProduct(img: myData['img'], title: myData['nome']);
        debugMsg(myData['img']);
        //cpl.add(cp);
        debugMsg(cpl.length.toString());
      }
    });
  }

  */