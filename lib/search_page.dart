import 'dart:async';
import 'dart:ffi';

import 'package:comparador2/carrinho.dart';
import 'package:comparador2/configs.dart';
import 'package:comparador2/main.dart';
import 'package:comparador2/produto_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'lib.dart';
import 'package:comparador2/no_internet.dart';

class StreamBuilderSearchPage extends StatefulWidget {
  var termo;
  //const StreamBuilderSearchPage({Key? key, required this.termo}): super(key: key);

  StreamBuilderSearchPage(termo) {
    this.termo = removeSpecialCharacters(termo);
  }

  @override
  State<StreamBuilderSearchPage> createState() =>
      _StreamBuilderSearchPageState();
}

class _StreamBuilderSearchPageState extends State<StreamBuilderSearchPage>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;
  var _streamController = StreamController<List<dynamic>>();
  var _scrollController = ScrollController();

  var _listCursorEnd = 0;

  var all_produtos = [];

  var loading = false;

  loadMoreProducts() {
    setState(() {
      _listCursorEnd += 10;
      loadProducts(false);
    });
  }

  loadProducts(bool refresh) {
    debugMsgDev("getting more products: " + _listCursorEnd.toString(),
        tag: "searchPageStream");

    if (refresh) {
      //reset da pagina
      _listCursorEnd = 0;
      all_produtos = [];
      debugMsgDev("refresh", tag: "searchPageStreamPrice");
    }

    Map<String, String> parametros = {
      'item': widget.termo,
      'sm': '',
      'param1': 'search',
      'page': _listCursorEnd.toString(),
      'filter': 'relevance'
    };

    for (var element in getNomesSM()) {
      parametros['sm'] = parametros['sm']! + element + '|';
    }

    debugMsgDev(parametros.toString(), tag: "searchPageStreamPrice");

    loading = true;
    getSearchResults(parametros).then((response) {
      all_produtos = all_produtos + response;
      debugMsgDev(all_produtos.toString(), tag: "seachPage");
      _streamController.add(all_produtos);
      loading = false;

      /*
      debugMsgDev("-------------------------------------",
          tag: "searchPageStreamPrice");
      for (int i = 0; i < response.length; i++) {
        debugMsgDev(response[i]['preco'].toString(),
            tag: "searchPageStreamPrice");
      }
      */
    });
  }

  @override
  void initState() {
    super.initState();
    debugMsgDev("init", tag: "searchPageStreamPrice");
    loadProducts(false);
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {
        debugMsgDev("List scroll at bottom", tag: "searchPageStream");
        loadMoreProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: ((context, constraints) {
      return StreamBuilder(
          stream: _streamController.stream,
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>> produtos) {
            if (produtos.hasData) {
              if (_listCursorEnd > produtos.data!.length) {
                _listCursorEnd = produtos.data!.length;
              }
              var lista_produtos = produtos.data as List<dynamic>;
              debugMsgDev(lista_produtos.toString(), tag: "searchPageStream");

              debugMsgDev(
                  "size of lista_produtos: " + lista_produtos.length.toString(),
                  tag: "searchPageStream");
              if (lista_produtos[0].toString() == "-1") {
                debugMsgDev("lista invalida", tag: "searchPageStream");
                return Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      "Não foram encontrado produtos com essa descrição",
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center,
                    ));
              }
              return RefreshIndicator(
                onRefresh: () async => loadProducts(true),
                child: Stack(
                  children: [
                    GridView.count(
                      controller: _scrollController,
                      crossAxisCount: 2,
                      children: lista_produtos.map((value) {
                        return cardBuilder(value);
                      }).toList(),
                    ),
                    if (loading) ...[
                      Positioned(
                          left: 0,
                          bottom: 20,
                          child: Container(
                            width: constraints.maxWidth,
                            child: Center(child: CircularProgressIndicator()),
                          ))
                    ]
                  ],
                ),
              );
            }
            return Center(
              child: CircularProgressIndicator(),
            );
          });
    }));
  }
}

class cardBuilder extends StatelessWidget {
  //const cardBuilder({ Key? key }) : super(key: key);
  static var tag_num = 0;
  var produto;
  cardBuilder(this.produto) {
    tag_num++;
  }

  @override
  Widget build(BuildContext context) {
    debugMsgDev("building card, tag: " + tag_num.toString(),
        tag: "searchPageF");
    debugMsgDev("produto: " + produto.toString(), tag: "searchPageF");
    return Card(
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProdutoWindowBuilder(
                        produto: produto,
                      )));
            },
            child: Column(
              children: [
                Text(
                  nameFormater(produto['nomeSM']),
                  style: TextStyle(
                      fontSize: 20,
                      color: getSMcolor(nameFormater(produto['nomeSM']))),
                ),
                Text(produto['marca']),
                Flexible(
                  child: Image.network(
                    produto['img'],
                    loadingBuilder: ((context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }),
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      debugMsgDev("error", tag: "searchPageCardImg");
                      return Image.asset('assets/images/error.png');
                    },
                  ),
                ),
                Container(width: 100, child: Text(produto['nome'])),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(produto['preco'].toString() + "€"),
                    (produto['desconto'].toString() == '0'
                        ? Container()
                        : Text(
                            produto['desconto']['preco_original'].toString() +
                                "€",
                            style: TextStyle(
                                decoration: TextDecoration.lineThrough))),
                  ],
                )
              ],
            ),
          ),
          Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  width: 40,
                  child: FloatingActionButton(
                      child: Icon(Icons.shopping_cart),
                      heroTag: getRandomTag(),
                      onPressed: () {
                        debugMsgDev(produto['nome'], tag: "searchPageF");
                        addProdutoCarrinho(produto, produto['sm']);
                      })))
        ],
      ),
    );
  }
}

class searchPage extends StatelessWidget {
  final pesquisa;

  searchPage({Key? key, required this.pesquisa}) : super(key: key);

  Map<String, String> parametros = {
    'item': 'arroz',
    'sm': 'continente',
    'param1': 'home'
  };
  Map<String, String> parametros2 = {
    'item': 'massa',
    'sm': 'pingoDoce',
    'param1': 'home'
  };

  @override
  Widget build(BuildContext context) {
    var ListaParam = [parametros, parametros2];
    debugMsgDev(parametros['param1'].toString(), tag: "searchPage");
    //return SliverPersistentHeader(pinned: true, delegate: Delegate());
    return FutureBuilder(
        future: getAll(ListaParam),
        builder: (context, produto_sm) {
          if (produto_sm.hasData) {
            debugMsgDev(produto_sm.data.runtimeType.toString(),
                tag: "searchPage");

            //lista de maps contendo todos os produtos
            var all_produtos = miscProducts(produto_sm.data as List<dynamic>);
            debugMsgDev("sorting", tag: "searchPage");
            all_produtos.sort((a, b) => a['preco'].compareTo(b['preco']));
            debugMsgDev("sorted", tag: "searchPage");
            debugMsgDev(all_produtos.toString(), tag: "searchPage");
            return SliverList(delegate:
                SliverChildBuilderDelegate((BuildContext context, int index) {
              if (index == 0) {
                debugMsgDev("index 0", tag: "searchPage");
                return StickyHeader(
                    header: Container(
                      color: Colors.red,
                      child: Text("asd"),
                    ),
                    content: Container());
              } else {
                return containerGreen();
              }
            }));
          }
          return SliverToBoxAdapter(
            child: Container(),
          );
        });
  }
}

class filterTopBar extends StatelessWidget {
  const filterTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar();
  }
}

//filtros
class Delegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.red,
    );
  }

  @override
  bool shouldRebuild(Delegate oldDelegate) {
    return false;
  }

  @override
  double get minExtent => 30;
  @override
  double get maxExtent => 60;
}

class SecondRoute extends StatelessWidget {
  const SecondRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Route'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}
