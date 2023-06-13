import 'package:comparador2/configs.dart';
import 'package:comparador2/lib.dart';
import 'package:flutter/material.dart';
import 'package:comparador2/carrinho.dart';

import 'graphic.dart';

class ProdutoWindowBuilder extends StatefulWidget {
  final produto;

  const ProdutoWindowBuilder({Key? key, required this.produto})
      : super(key: key);

  @override
  State<ProdutoWindowBuilder> createState() => _ProdutoWindowBuilderState();
}

//main method com os container dos dados do produto
class _ProdutoWindowBuilderState extends State<ProdutoWindowBuilder> {
  goToGraphicMenu(BuildContext context, String link) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
          body: Center(
              child: Scaffold(
                  appBar: AppBar(
                    title: Text("Histórico de Preço"),
                  ),
                  body: Center(
                    child: DataChartPage(link),
                  )))),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final produto = widget.produto;

    Map<String, String> param = {
      'param1': 'produto',
      'sm': produto['nomeSM'],
      'item': produto['link']
    };

    return Scaffold(
        appBar: AppBar(
          title: Text(nameFormater(produto['nomeSM'])),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  goToGraphicMenu(context, produto['link']);
                },
                child: Icon(
                  Icons.add_chart_rounded,
                  size: 50,
                ),
              ),
            )
          ],
        ),
        body: ListView(
          children: [
            Card(elevation: 5, child: ImagemContainer(link: produto['img'])),
            Card(elevation: 5, child: DetalhesContainer(produto: produto)),
            Card(elevation: 5, child: InfoAdicional(produto: produto)),
            Card(elevation: 5, child: OtherProducts(produto: produto)),
          ],
        ));
  }
}

class ImagemContainer extends StatelessWidget {
  final link;
  const ImagemContainer({Key? key, required this.link}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugMsgDev(link.toString(), tag: "produtoWindow");
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: ImageNetworkBuilder(link: link),
      ),
    );
  }
}

class DetalhesContainer extends StatelessWidget {
  final produto;
  const DetalhesContainer({Key? key, required this.produto}) : super(key: key);

  final height = 250.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey,
        //border: Border(bottom: BorderSide(width: 2.0, color: Colors.black),),
      ),
      height: height,
      width: double.infinity,
      child: Column(
        children: [
          //1º container: nomes
          Container(
            height: height / 3 + 32,
            child: Column(
              children: [
                Container(
                  child: Text(
                    produto['nome'],
                    style: TextStyle(fontSize: 30),
                  ),
                ),
                Container(
                    child: Text(
                  produto['marca'],
                  style: TextStyle(fontSize: 20),
                )),
                Container(
                  child: Text(
                    produto['quantidade'] + " " + produto['quantidade_u_m'],
                    style: TextStyle(fontSize: 19),
                  ),
                ),
              ],
            ),
          ),
          //precos e butao
          Expanded(
              child: Container(
            child: Row(
              children: [
                //precos
                Container(
                  width: 250,
                  child: Center(
                    child: containerPrices(produto: produto),
                  ),
                ),

                //butao
                Expanded(
                  child: Center(
                    child: FloatingActionButton(
                      child: Icon(Icons.shopping_cart),
                      onPressed: () {
                        addProdutoCarrinho(produto, produto['nomeSM']);
                      },
                    ),
                  ),
                )
              ],
            ),
          ))
        ],
      ),
    );
  }
}

//container com os precos
class containerPrices extends StatelessWidget {
  final produto;
  const containerPrices({Key? key, required this.produto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 70,
        width: 200,

        //coluna, em que a 1ª row tem uma Row(com o preco e desconto) e a 2ª tem o preco/quantidade
        child: Column(
          children: [
            Expanded(
                child: Row(children: [
              Text(
                produto['preco'].toString() + '€',
                style: TextStyle(fontSize: 25),
              ),
              Spacer(),
              Text(
                produto['desconto'] == 0
                    ? ''
                    : produto['desconto']['preco_original'].toString() + "€",
                style: TextStyle(
                    fontSize: 21, decoration: TextDecoration.lineThrough),
              )
            ])),
            Expanded(
                child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                produto['preco_unidade'].toString() +
                    "€\\" +
                    produto['quantidade_u_m'],
                style: TextStyle(fontSize: 20),
              ),
            ))
          ],
        ));
  }
}

class InfoAdicional extends StatelessWidget {
  final produto;
  const InfoAdicional({Key? key, required this.produto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, String> param = {
      'param1': 'produto',
      'sm': produto['nomeSM'],
      'item': produto['link']
    };
    return FutureBuilder(
      future: readJson(param),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final info = snapshot.data as List<dynamic>;
          debugMsgDev(info[0].toString(), tag: "produtoAdicional");
          if (info[0].toString() == '-1') {
            return Container();
          }
          return Column(children: [
            ExpansionTile(
              title: Text("Informação Adicional"),
              children: [Text(info[0]['info_adicional'])],
            ),
            ExpansionTile(
              title: Text("Informação Nutricional"),
              children: [Text(info[0]['info_nutricional'])],
            )
          ]);
        }
        return Container();
      },
    );
  }
}

class OtherProducts extends StatelessWidget {
  final produto;
  const OtherProducts({Key? key, required this.produto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getComparisonProduct(produto['nome'], produto['quantidade'],
          produto['marca'], produto['preco'], produto['quantidade_u_m']),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final produtos = snapshot.data as List<dynamic>;
          for (int i = 0; i < produtos.length; i++) {
            if (produtos[i]['nomeSM'] == produto['nomeSM'] ||
                !getNomesSM().contains(produtos[i]['nomeSM'])) {
              produtos.remove(produtos[i]);
            }
          }
          debugMsgDev("size of equivalents:" + produtos.length.toString(),
              tag: "produtoWindow");
          return Container(
              height: 400,
              width: double.infinity,
              color: Colors.grey,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: produtos.length,
                separatorBuilder: (context, index) {
                  return Container(
                    width: 10,
                  );
                },
                itemBuilder: (context, index) {
                  debugMsgDev("produto: " + produtos[index].toString(),
                      tag: "produtoWindow");
                  return cardsBuilder(produtos[index], 400 - 10, index);

                  //return cardsGenerator(produtos[index]);
                },
              ));
        }
        return Container();
      },
    );
  }
}

class cardsBuilder extends StatelessWidget {
  //const cardsGenerator({Key? key}) : super(key: key);
  static var tag_num = 0;
  //map correspondente ao produto
  final produto;
  final total_height;
  final index;

  final double bigTextSize = 18;
  final double medTextSize = 14;
  final double smallTextSize = 14;

  cardsBuilder(this.produto, this.total_height, this.index) {
    tag_num++;
  }

  Widget buildFittedBox(String msg, double textSize,
      {crossed = false, isSM = false}) {
    if (msg == '') {
      msg = " ";
    }
    var textStyle = null;
    if (crossed) {
      textStyle =
          TextStyle(fontSize: textSize, decoration: TextDecoration.lineThrough);
    } else {
      if (isSM) {
        textStyle = TextStyle(fontSize: textSize, color: getSMcolor(msg));
      } else {
        textStyle = TextStyle(
          fontSize: textSize,
        );
      }
    }

    debugMsgDev("building fitted box: " + msg, tag: "produtoWindow");
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: Text(
        msg,
        style: textStyle,
      ),
    );
  }

  //medidas:
  //titulos: 1/4
  //imagem: 1/2
  //preco: 1/4

  @override
  Widget build(BuildContext context) {
    if (produto.toString() == '-1' || produto.toString() == '[]') {
      debugMsgDev("erro ao obter produtos extra", tag: "produtoWindow");
      return Container();
    }
    debugMsgDev("building produtos extra", tag: "produtoWindow");
    return LayoutBuilder(builder: (BuildContext context, constraints) {
      double total_width = MediaQuery.of(context).size.width / 2;
      debugMsgDev(produto.toString(), tag: "produtoWindow");
      return Container(
          width: total_width,
          //color: Colors.red,

          //card com imagem, nome, marca, ...
          child: Card(
            elevation: 10,
            child: Column(children: [
              //titulos (NomeSM, Nome, MarcaSM, QuantidadeSM)
              Container(
                height: total_height / 4,
                width: double.infinity,
                //color: Colors.red,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildFittedBox(nameFormater(produto['nomeSM']), 30,
                        isSM: true),
                    buildFittedBox(produto['nome'], 25),
                    buildFittedBox(produto['marca'], 20),
                  ],
                ),
              ),
              //imagem
              Container(
                height: total_height / 2,
                width: double.infinity - 10,
                //color: Colors.blue,
                child: Card(
                  elevation: 10,
                  child: Image.network(
                    produto['img'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              //precos, quantidade e butao (quantidade = 1/4, precos e butao = 3/4)
              Container(
                height: total_height / 4,
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      height: total_height / 16,
                      child: buildFittedBox(
                          produto['quantidade'].toString() +
                              produto['quantidade_u_m'],
                          smallTextSize),
                    ),

                    // row que vai separar os precos do butao
                    Container(
                      height: (total_height / 4) * (3 / 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          //container com os precos
                          Container(
                            height: (total_height / 4) * (3 / 4),
                            width: 0.6 * total_width,
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    children: [
                                      buildFittedBox(
                                          produto['preco'].toString() + "€",
                                          bigTextSize), //preco
                                      Spacer(),
                                      produto['desconto'].toString() == '0'
                                          ? Container()
                                          : buildFittedBox(
                                              produto['desconto']
                                                          ['preco_original']
                                                      .toString() +
                                                  "€",
                                              smallTextSize,
                                              crossed: true),
                                      Spacer(),
                                    ],
                                  ),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: buildFittedBox(
                                          produto['preco_unidade'].toString() +
                                              "€/" +
                                              produto['quantidade_u_m'],
                                          smallTextSize)),
                                ]),
                          ),

                          //butao
                          FittedBox(
                            fit: BoxFit.fitHeight,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FloatingActionButton(
                                  heroTag: index,
                                  child: Icon(Icons.shopping_cart),
                                  onPressed: () {
                                    addProdutoCarrinho(
                                        produto, produto['nomeSM']);
                                  }),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ));
    });
  }
}

//------------------------------------------------------------------------------------------

class produtoWindow extends StatelessWidget {
  final produto;

  const produtoWindow({Key? key, required this.produto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //tamanhos de letra para os diversos text a serem apresentados
    double bigLetterSize = 25;
    double medLetterSize = 15;
    double smallLetterSize = 10;

    //coluna com o nome, marca e quantidade (embalagem)
    Expanded topColumn() {
      return Expanded(
        flex: 4, //40%
        child: Column(children: [
          //nome
          Expanded(
            flex: 5,
            child: Container(
                child: Text(produto['nome'],
                    style: TextStyle(fontSize: bigLetterSize)),
                alignment: Alignment.topCenter),
          ),
          //marca
          Expanded(
              flex: 3,
              child: Container(
                  child: Text(produto['marca'],
                      style: TextStyle(fontSize: medLetterSize)),
                  alignment: Alignment.topCenter)),
          //quantidade
          Expanded(
              flex: 2,
              child: Container(
                child: Text(produto['quantidade'],
                    style: TextStyle(fontSize: smallLetterSize)),
                alignment: Alignment.topCenter,
              ))
        ]),
      );
    }

    //parte com o preco atual, original e preco_kg
    Expanded columnPrecos() {
      return Expanded(
        flex: 4,
        //2 secçoes: precos(atual e original) e preco_kg
        child: Column(
          children: [
            //2 secoes: preco atual e preco original
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      produto['preco'].toString() + "€",
                      style:
                          TextStyle(color: Colors.red, fontSize: bigLetterSize),
                    ),
                  ),
                  Expanded(
                      child: Text(
                    produto['desconto'] == 0
                        ? ""
                        : produto['desconto']['preco_original'].toString() +
                            "€",
                    style: TextStyle(
                      color: Colors.grey[850],
                      fontSize: smallLetterSize,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ))
                ],
              ),
            ),

            Expanded(
              flex: 5,
              child: Text(
                produto['preco_quantidade_u_m'].toString() +
                    "€/" +
                    produto['quantidade_u_m'],
                style: TextStyle(fontSize: medLetterSize),
              ),
            ),
          ],
        ),
      );
    }

    Map<String, String> param = {
      'param1': 'produto',
      'sm': produto['nomeSM'],
      'item': produto['link']
    };

    debugMsgDev(param.toString(), tag: "produtoWindow");

    return Scaffold(
        appBar: AppBar(
          title: Text(produto['nome']),
        ),
        body: ListView(
          children: [
            FutureBuilder(
              future: readJson(param),
              builder: (context, desc_produto) {
                if (desc_produto.hasData) {
                  List<dynamic> nl = desc_produto.data as List<dynamic>;
                  debugMsgDev(nl.toString(), tag: "produtoWindow");
                  return Column(
                    children: [
                      //imagem
                      Align(
                          //imagem
                          child: Container(
                            height: 300,
                            color: Colors.white,
                            width: double.infinity,
                            child: Image.network(
                              produto['img'],
                              fit: BoxFit.fitHeight,
                              loadingBuilder:
                                  ((context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }),
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                                debugMsgDev("error", tag: "searchPageCardImg");
                                return Image.asset('assets/images/error.png');
                              },
                            ),
                          ),
                          alignment: Alignment.topCenter),
                      //container com os precos, nome, marca, ...
                      Container(
                        color: Colors.grey,
                        height: 200,
                        child: Column(children: [
                          //nome, marca, quantidade
                          topColumn(),

                          //preco(s), desconto, butões
                          Expanded(
                            flex: 6, //60%,

                            //+-30% para cada (3 secçoes)
                            child: Row(
                              children: [
                                //preco original, atual, preco/kg
                                columnPrecos(),

                                //mostrar promocao (caso haja)
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Spacer(),
                                      Expanded(
                                          child: produto['desconto'] == 0
                                              ? Spacer()
                                              : Center(
                                                  child: Container(
                                                    color: Colors.amber,
                                                    width: 70,
                                                    child: Center(
                                                      child: Text(
                                                          produto['desconto']
                                                                      ['valor']
                                                                  .toStringAsFixed(
                                                                      0) +
                                                              "%",
                                                          style: TextStyle(
                                                              fontSize:
                                                                  bigLetterSize)),
                                                    ),
                                                  ),
                                                )),
                                      Spacer(),
                                    ],
                                  ),
                                ),

                                //butoes
                                Expanded(
                                  flex: 3,
                                  child: FloatingActionButton(
                                    onPressed: null,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ]),
                      ),
                      //descricoes do produto
                      ExpansionTile(
                          title: Text("Informação adicional"),
                          children: [Text(nl[0]['info_adicional'])]),
                      ExpansionTile(
                        title: Text("Informação nutricional"),
                        children: [Text(nl[0]['info_nutricional'])],
                      ),
                    ],
                  );
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
            FutureBuilder(
                future: getComparisonProduct(
                    produto['nome'],
                    produto['quantidade'],
                    '-1',
                    produto['preco'],
                    produto['quantidade_u_m']),
                builder: ((context, snapshot) {
                  if (snapshot.hasData) {
                    var produtos = snapshot.data as List;
                    debugMsgDev("size: " + produtos.length.toString(),
                        tag: "produtoWindow");
                    return otherProducts(
                      produtos: produtos,
                    );
                  }
                  return Container();
                }))
          ],
        ));
  }
}

class otherProducts extends StatelessWidget {
  final List<dynamic> produtos;
  const otherProducts({Key? key, required this.produtos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugMsgDev(produtos.toString(), tag: "produtoWindow");
    return Expanded(
      child: Container(
        height: 200,
        width: double.infinity,
        child: ListView.builder(
          itemCount: produtos.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return Container(
              height: 200,
              child: Text(produtos[index].toString()),
            );
          },
        ),
      ),
    );

    Row(
      children: produtos.map((produto) => cardsGenerator(produto)).toList(),
    );
  }
}

//"template" para cada card dos produtos alternativos
class cardsGenerator extends StatelessWidget {
  //const cardsGenerator({Key? key}) : super(key: key);
  static var tag_num = 0;
  //map correspondente ao produto
  final produto;

  final double bigTextSize = 18;
  final double medTextSize = 14;
  final double smallTextSize = 14;

  cardsGenerator(this.produto) {
    tag_num++;
  }

  @override
  Widget build(BuildContext context) {
    debugMsgDev("produto: " + produto.toString(), tag: "produtoWindow");
    if (produto.toString() == '-1') {
      return Container();
    }
    return Container(
      height: 300,
      width: 300,
      child: Card(
        elevation: 10,
        //coluna no interior do card
        child: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                produto['nomeSM'],
                style: TextStyle(color: getSMcolor(produto['nomeSM'])),
              ),
              Container(
                height: 60,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    produto['nome'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: bigTextSize),
                  ),
                ),
              ),
              Text(
                produto['marca'],
                style: TextStyle(fontSize: medTextSize),
              ),

              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ProdutoWindowBuilder(produto: produto)));
                },
                child: Flexible(
                  child: Image.network(produto['img']),
                ),
              ),
              Text(
                produto['quantidade'],
                style: TextStyle(fontSize: smallTextSize),
              ),

              //2 rows: precos, e butao
              Expanded(
                child: Row(
                  children: [
                    //precos
                    Expanded(
                      child: Column(
                        children: [
                          //2 rows: preco e a outra para preco_original
                          Row(
                            children: [
                              Align(
                                  child: Text(
                                produto['preco'].toString() + "€",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: bigTextSize, color: Colors.red),
                              )),
                              SizedBox(width: 10), //espaco entre os precos
                              Align(
                                  child: Text(
                                produto['desconto'] == 0
                                    ? ""
                                    : produto['desconto']['preco_original']
                                            .toString() +
                                        "€",
                                style: TextStyle(
                                    fontSize: medTextSize,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[400]),
                              ))
                            ],
                          ),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                produto['preco_quantidade_u_m'].toString() +
                                    "€/kg",
                                textAlign: TextAlign.left,
                              )),
                        ],
                      ),
                    ),

                    //butão
                    Expanded(
                      flex: 5,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          child: FloatingActionButton(
                              heroTag: tag_num,
                              onPressed: () {
                                addProdutoCarrinho(produto, "Continente");
                              }),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
