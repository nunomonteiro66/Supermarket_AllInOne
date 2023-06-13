import 'dart:collection';

import 'package:comparador2/carrinho.dart';
import 'package:comparador2/lib.dart';
import 'package:comparador2/mapa.dart';
import 'package:flutter/material.dart';

Future<Map> getAllProducts(var lista_produtos) async {
  var produtos_sm = [];

  //mapa de mapas: mapa que contem mapas com a lista de produtos e o preco total
  //o nomeSM serve como key para designar o subMapa
  Map all_produtos = {};

  //para cada produto da lista de produtos, pede os equivalentes a esse produto
  for (var i = 0; i < lista_produtos.length; i++) {
    debugMsgDev("------------------------", tag: "comparadorFinal");
    var tmp = await getComparisonProduct(
        lista_produtos[i]['nome'],
        lista_produtos[i]['quantidade'],
        lista_produtos[i]['marca'],
        lista_produtos[i]['preco'],
        lista_produtos[i]['quantidade_u_m']);
    debugMsgDev("tmp: $tmp", tag: "comparadorFinal");

    debugMsgDev("erro ao obter os produtos", tag: "comparadorFinal");

    //tmp = o mesmo produto de todos os supermercados
    for (var i = 0; i < tmp.length; i++) {
      debugMsgDev(tmp[i].toString(), tag: "comparadorFinal");
      if (!tmp[i].isEmpty) {
        if (tmp[0].toString() == "-1") {
          //nao foi possivel obter os produtos
          return {};
        }
        var nomeSM = tmp[i]['nomeSM'];
        debugMsgDev(nomeSM, tag: "comparadorFinal");
        try {
          all_produtos[nomeSM]['produtos'].add(tmp[i]);
        } catch (e) {
          //ainda nao foi criado um mapa para este supermercado
          all_produtos[nomeSM] = {};
          all_produtos[nomeSM]['produtos'] = [tmp[i]];
        }
      }
    }
  }

  debugMsgDev("----------------------------\n--------------------------",
      tag: "comparadorFinal");

  //calcular o preco final
  for (var key in all_produtos.keys) {
    var tmp = all_produtos[key]['produtos']; //array de produtos neste SM
    var preco_total = 0.0;
    for (var p in tmp) {
      //para cada produto no array
      preco_total += (p['preco']);
    }
    all_produtos[key]['preco_total'] = [preco_total];
  }

  var sortedKeys = all_produtos.keys.toList(growable: false)
    ..sort((k1, k2) => all_produtos[k1]['preco_total'][0]
        .compareTo(all_produtos[k2]['preco_total'][0]));

  LinkedHashMap all_produtos_sorted = new LinkedHashMap.fromIterable(sortedKeys,
      key: (k) => k, value: (k) => all_produtos[k]);

  debugMsgDev("returning all_produtos", tag: "comparadorFinal");
  debugMsgDev(all_produtos_sorted.toString(), tag: "comparadorFinal");

  return all_produtos_sorted;
}

class ComparadorFinalMain extends StatelessWidget {
  final lista_produtos;
  const ComparadorFinalMain({Key? key, required this.lista_produtos})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugMsgDev("lista: " + lista_produtos.toString(), tag: "comparadorFinal");
    return MaterialApp(
      title: "Comparador",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Comparação final"),
          leading: new IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: new Icon(Icons.arrow_back)),
        ),
        body: BuildComparadorFinal(lista_produtos: lista_produtos),
      ),
    );
  }
}

class BuildComparadorFinal extends StatefulWidget {
  final lista_produtos;
  const BuildComparadorFinal({Key? key, required this.lista_produtos})
      : super(key: key);

  @override
  State<BuildComparadorFinal> createState() => _BuildComparadorFinalState();
}

class _BuildComparadorFinalState extends State<BuildComparadorFinal> {
  @override
  Widget build(BuildContext context) {
    debugMsgDev(widget.lista_produtos.toString(), tag: "comparadorFinal");
    return FutureBuilder(
        future: getAllProducts(lista_produtos),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            Map listaProdutos = snapshot.data as Map;

            debugMsgDev(
                "lista de produtos recebida:\n\n" + listaProdutos.toString(),
                tag: "comparadorFinal");
            //nao foi possivel obter os produtos
            if (listaProdutos.isEmpty) {
              debugMsgDev("nao foi possivel obter os produtos",
                  tag: "comparadorFinal");
              return Center(
                child: Text(
                  "Não foi possível obter os produtos",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              );
            }

            List keys = [];
            for (var key in listaProdutos.keys) {
              keys.add(key);
            }
            debugMsgDev(listaProdutos.toString(), tag: "comparadorFinal");
            return ListView.separated(
                itemBuilder: (context, index) {
                  return ExpansionTileBuilder(
                    produtos: listaProdutos[keys[index]]['produtos'],
                    nomeSM: keys[index],
                    preco_total: listaProdutos[keys[index]]['preco_total'],
                  );
                },
                separatorBuilder: (context, index) {
                  return Container(
                    width: 10,
                  );
                },
                itemCount: listaProdutos.length);
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        }));
  }
}

class ExpansionTileBuilder extends StatelessWidget {
  final List<dynamic> produtos;
  final nomeSM;
  final preco_total;
  const ExpansionTileBuilder(
      {Key? key,
      required this.produtos,
      required this.nomeSM,
      required this.preco_total})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var nomeSMF = nameFormater(nomeSM);
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              nomeSMF + " | " + preco_total[0].toStringAsFixed(2) + "€",
              style: TextStyle(color: getSMcolor(nomeSMF)),
            ),
            Spacer(),
            FloatingActionButton(
                heroTag: getRandomTag(),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MapaHome(nomeSM)));
                },
                child: Icon(Icons.map)),
          ],
        ),
        children: produtos.map((produto) {
          return Column(children: [
            productCard(produto),
            //divider between products
            Divider(
              color: Colors.black,
            ),
          ]);
        }).toList(),
      ),
    );
  }
}

class productCard extends StatelessWidget {
  //const productCard({ Key? key }) : super(key: key);
  final produto;

  productCard(this.produto);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      //color: Colors.amber,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
              child: ImageNetworkBuilder(
            link: produto['img'],
          )),
          Container(
            width: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Center(
                    child:
                        Text(produto['nome'], style: TextStyle(fontSize: 15))),
                Center(
                    child:
                        Text(produto['marca'], style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
          Center(
            child: Text(produto['preco'].toString() + "€",
                style: TextStyle(fontSize: 20, color: Colors.red)),
          )
        ],
      ),
    );
  }
}
