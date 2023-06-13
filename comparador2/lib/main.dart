// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

//dns: mypythonapi.mywire.org

import 'dart:async';
import 'dart:io';
import 'package:comparador2/carrinho.dart';
import 'package:comparador2/introduction.dart';
import 'package:comparador2/lib.dart';
//import 'package:comparador2/main%20-%20Copy.dart';
import 'package:comparador2/no_internet.dart';
import 'package:flutter/material.dart';
import 'package:comparador2/search_page.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'produto_window.dart';
import 'dart:convert';
import 'package:comparador2/configs.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main() {
  runApp(mainApp());
}

void debugMsg(String msg) {
  stderr.writeln(msg);
}

class mainApp extends StatefulWidget {
  const mainApp({Key? key}) : super(key: key);

  @override
  State<mainApp> createState() => _mainAppState();
}

class _mainAppState extends State<mainApp> with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;
  bool refresh = false;

  var pesquisa; //string
  var errorpage = false;

  void ErrorPage() {
    errorpage = true;
    setState(() {});
  }

  void Reload() {
    refresh = true;
    debugMsgDev("reloading", tag: "reloading");
    setState(() {});
  }

  var _streamController = StreamController<List<dynamic>>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugMsgDev(pesquisa.toString(), tag: "pesquisaTopBar");
    return FutureBuilder<bool>(
      future: checkConnection(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          //verifica se existe conexão com o servidor
          if (snapshot.data == false) {
            return noInternetPage(Reload);
          }
          //ha conexao, pagina normal
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            darkTheme: ThemeData.dark(),
            home: Scaffold(
              drawer: UserSettings(Reload),
              body: RefreshIndicator(
                onRefresh: () async {
                  Reload();
                },
                child: CustomScrollView(
                  slivers: <Widget>[
                    //-------------------------------------------------------------------TOP BAR
                    topBar(),
                    //pesquisa == null significa que não ha
                    // nunhum produto a ser pesquisado, logo vai para a "home page"

                    supermermarketsColumns(
                      errorPage: ErrorPage,
                      refreshPage: Reload,
                      refresh: refresh,
                      key: ObjectKey(getRandomTag()),
                    )

                    /*
                              SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                  //coluna com o titulo e o container, que vai ter os cards
                  return supermarketsColumn();
                              }, childCount: 1))
                              */
                  ],
                ),
              ),
              //bottomNavigationBar: DownBar()
            ),
          );
        }
        return introductionPage();
      },
    );
  }
}

class topBar extends StatefulWidget {
  const topBar({Key? key}) : super(key: key);

  @override
  State<topBar> createState() => _topBarState();
}

class _topBarState extends State<topBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      title: SearchBar(),
      actions: <Widget>[
        //-------------------------------------------------------------------Icon Basket
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => carrinho()));
          },
        ),
      ],
    );
  }
}

class supermermarketsColumns extends StatefulWidget {
  final Function() errorPage;
  final Function() refreshPage;
  final bool refresh;
  const supermermarketsColumns(
      {Key? key,
      required this.errorPage,
      required this.refreshPage,
      required this.refresh})
      : super(key: key);

  @override
  State<supermermarketsColumns> createState() => _supermermarketsColumnsState();
}

class _supermermarketsColumnsState extends State<supermermarketsColumns> {
  //const supermarketsColumn({Key? key}) : super(key: key);

  //lista com os Map's de cada produto
  var listProdutos = [];

  void dispose() {
    super.dispose();
  }

  Future<void> refreshPage() async {
    widget.refreshPage();
    await Future.delayed(Duration(seconds: 0));
  }

  //retorna a lista de produtos a ser mostrado na homepage
  Future<List> getHomeProducts() async {
    //await SPListaSM().buildListaSM();  //inicia a class que vai conter os SM

    //construcao dos parametros para pedir à API
    var parametros = [];
    var nomesSM = getNomesSM(); //lista de SM ativos
    debugMsgDev(nomesSM.toString(), tag: "homeProducts");
    for (var i = 0; i < nomesSM.length; i++) {
      Map<String, String> param = {
        "sm": nomesSM[i],
        "param1": 'home',
        'item': '',
      };
      parametros.add(param);
    }

    return getAll(parametros); //retorna o pedido
  }

  //var _streamController = StreamController<List<dynamic>>();

  void loadProducts(var _streamController) {
    // TODO: implement initState
    //super.initState();
    //adiciona os produtos no listener
    getHomeProducts().then((value) {
      _streamController.add(value);
    });
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    var _streamController = StreamController<List<dynamic>>();

    List<dynamic> allProdutos = [];
    loadProducts(_streamController);
    debugMsgDev("build: " + allProdutos.length.toString(),
        tag: "supermarketColumns");
    return StreamBuilder(
      stream: _streamController.stream,
      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
        if (snapshot.hasData) {
          allProdutos = snapshot.data!;
          debugMsgDev(snapshot.data!.length.toString(),
              tag: "supermarketColumns");
          //se tem dados, retorna a lista de produtos
          return Colunas(allProdutos);
        }
        return SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget Colunas(produto_sm) {
    return SliverList(
        //obriga a coluna a ser reconstruida quando alterado os supermercados ativos/inativos
        delegate: SliverChildBuilderDelegate(
            //primeiro index (lista de supermercados)
            (BuildContext context, int index_1) {
      //produto - lista de todos os supermercados (com os produtos la dentro)
      var produto = produto_sm![index_1][0];
      debugMsgDev("asd", tag: "erroConexao");
      var nomeSM = nameFormater(produto['nomeSM']);
      //representa o titulo e todos os cards do supermercado em questao
      return Container(
        height:
            450, //tamanho, considerando tambem o espaco para a lista do proximo supermercado
        width: double.infinity,
        child: Column(
          children: [
            //nome do supermercado
            Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(width: 3.0, color: getSMcolor(nomeSM)))),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    " " + nomeSM,
                    style: TextStyle(color: getSMcolor(nomeSM), fontSize: 30),
                  )),
            ),
            //container com o listviewer, que vai conter os cards
            Container(
              height: 380,
              width: double.infinity,
              child: ListView.builder(
                itemCount: produto['listaProdutos'].length,
                scrollDirection: Axis.horizontal,
                //segundo index (dentro do supermercado)
                itemBuilder: (context, index_2) {
                  //container com card de cada produto
                  return Container(
                    height: double.infinity,
                    width: 220,
                    child: cardsGenerator(produto['listaProdutos'][index_2]),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }, childCount: produto_sm!.length));
  }

  /*
  @override
  Widget build(BuildContext context) {
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
    Map<String, String> parametros3 = {
      'item': 'natas',
      'sm': 'auchan',
      'param1': 'home'
    };

    
    

    //var ListaParam = [parametros, parametros2, parametros3];
    
    return FutureBuilder<List<dynamic>>(
        future: getHomeProducts(),
        builder: (context, produto_sm) {
          debugMsgDev(produto_sm.data.toString());
          //---------------------------------------------------------------------produto corresponde ao mapa com os produtos de cada supermercado
          if (produto_sm.hasData) {
            debugMsgDev("building columns", tag: "homeProducts");
            //-------------------------------------------------------------------colunas na vertical, com os container que vai ter os artigos
            return SliverList(
                delegate: SliverChildBuilderDelegate(
                    //primeiro index (lista de supermercados)
                    (BuildContext context, int index_1) {
              //produto - lista de todos os supermercados (com os produtos la dentro)
              var produto = produto_sm.data![index_1][0];
              debugMsgDev("asd", tag: "erroConexao");
    
              //representa o titulo e todos os cards do supermercado em questao
              return Container(
                height:
                    450, //tamanho, considerando tambem o espaco para a lista do proximo supermercado
                width: double.infinity,
                child: Column(
                  children: [
                    //nome do supermercado
                    Container(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(width: 3.0, color: getSMcolor(produto['nomeSM'])))),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            " "+produto['nomeSM'],
                            style: TextStyle(color: getSMcolor(produto['nomeSM']), fontSize: 30),
                          )),
                    ),
                    //container com o listviewer, que vai conter os cards
                    Container(
                      height: 380,
                      width: double.infinity,
                      child: ListView.builder(
                        itemCount: produto['listaProdutos'].length,
                        scrollDirection: Axis.horizontal,
                        //segundo index (dentro do supermercado)
                        itemBuilder: (context, index_2) {
                          //container com card de cada produto
                          return Container(
                            height: double.infinity,
                            width: 220,
                            child: cardsGenerator(
                                produto['listaProdutos'][index_2]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: produto_sm.data!.length));
          }
          return SliverToBoxAdapter(
              child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator()));
        });
    
  }

  */
}

class SupermarketColumns extends StatelessWidget {
  //const SupermarketColumns({Key? key}) : super(key: key);
  SupermarketColumns();

  //retorna a lista de produtos a ser mostrado na homepage
  Future<List> getHomeProducts() async {
    //await SPListaSM().buildListaSM();  //inicia a class que vai conter os SM

    //construcao dos parametros para pedir à API
    var parametros = [];
    var nomesSM = getNomesSM(); //lista de SM ativos
    debugMsgDev(nomesSM.toString(), tag: "homeProducts");
    for (var i = 0; i < nomesSM.length; i++) {
      Map<String, String> param = {
        "sm": nomesSM[i],
        "param1": 'home',
        'item': '',
      };
      parametros.add(param);
    }

    return getAll(parametros); //retorna o pedido
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getHomeProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Colunas(snapshot.data);
          }
          return SliverToBoxAdapter(
              child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator()));
        });
  }

  Widget Colunas(produto_sm) {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
            //primeiro index (lista de supermercados)
            (BuildContext context, int index_1) {
      //produto - lista de todos os supermercados (com os produtos la dentro)
      var produto = produto_sm![index_1][0];
      debugMsgDev("asd", tag: "erroConexao");

      //representa o titulo e todos os cards do supermercado em questao
      return Container(
        height:
            450, //tamanho, considerando tambem o espaco para a lista do proximo supermercado
        width: double.infinity,
        child: Column(
          children: [
            //nome do supermercado
            Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          width: 3.0, color: getSMcolor(produto['nomeSM'])))),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    " " + produto['nomeSM'],
                    style: TextStyle(
                        color: getSMcolor(produto['nomeSM']), fontSize: 30),
                  )),
            ),
            //container com o listviewer, que vai conter os cards
            Container(
              height: 380,
              width: double.infinity,
              child: ListView.builder(
                itemCount: produto['listaProdutos'].length,
                scrollDirection: Axis.horizontal,
                //segundo index (dentro do supermercado)
                itemBuilder: (context, index_2) {
                  //container com card de cada produto
                  return Container(
                    height: double.infinity,
                    width: 220,
                    child: cardsGenerator(produto['listaProdutos'][index_2]),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }, childCount: produto_sm!.length));
  }
}

//TextField search bar
class SearchBar extends StatefulWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  void loadSugestoes() async {
    await SPListaSugestoes()
        .buildListaSugestoes(); //instancia a classe que vai conter as sugestoes
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadSugestoes();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showSearch(context: context, delegate: ProductSearch());
      },
      child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              border: Border.all(
            color: Colors.black,
            width: 1.0,
          )),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              child: Flexible(
                  child: Text(
                "  Search",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              )),
            ),
            Spacer(),
            IconButton(
              color: Colors.grey,
              onPressed: () {
                showSearch(context: context, delegate: ProductSearch());
              },
              icon: Icon(Icons.search),
            )
          ])),
    );

    TextField(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: 'Enter a search term',
      ),
      onSubmitted: (String value) {
        debugMsgDev("a pesquisar " + value, tag: "pesquisaTopBar");
        //widget.pesquisa(value);
      },
    );
  }
}

class ProductSearch extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    SPListaSugestoes()
        .addSugestao(query); //adiciona a sugestao a lista de sugestoes
    return StreamBuilderSearchPage(
      query,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    SPListaSugestoes().buildListaSugestoes();
    return ListView.builder(
        itemCount: SPListaSugestoes.listaSugestoes.length,
        itemBuilder: (context, index) {
          final suggestion = SPListaSugestoes.listaSugestoes[index];
          return ListTile(
            title: Text(suggestion),
            onTap: () {
              query = suggestion;
              showResults(context);
            },
          );
        });
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
          IconButton(iconSize: 30, onPressed: null, icon: Icon(Icons.home)),
          IconButton(iconSize: 30, onPressed: null, icon: Icon(Icons.person))
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
    debugMsgDev("building cards, tag:" + tag_num.toString(), tag: "main");
    return Card(
      //coluna no interior do card
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: Container(
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
              child: ImageNetworkBuilder(link: produto['img']),
            ),
          ),
          Text(
            produto['quantidade'] + " " + produto['quantidade_u_m'],
            style: TextStyle(fontSize: smallTextSize),
          ),

          //2 rows: precos, e butao
          Row(
            children: [
              //precos
              Column(
                children: [
                  //2 rows: preco e a outra para preco_original
                  Container(
                    width: 110,
                    child: Row(
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
                  ),
                  Container(
                    width: 100,
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          produto['quantidade_u_m'] == ''
                              ? ""
                              : //se o produto nao tiver €/un, nao mostra nada
                              produto['preco_unidade'].toString() +
                                  "€/" +
                                  produto['unidade'],
                          textAlign: TextAlign.left,
                        )),
                  ),
                ],
              ),

              //butão
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    child: FloatingActionButton(
                        child: Icon(Icons.shopping_cart),
                        heroTag: tag_num,
                        onPressed: () {
                          addProdutoCarrinho(produto, "Continente");
                        }),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class UserSettings extends StatefulWidget {
  //const UserSettings({Key? key}) : super(key: key);
  Function _reload;
  UserSettings(this._reload);

  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  @override
  Widget build(BuildContext context) {
    //Map<String, bool> listaSM = SPListaSM.listaSM; //mapa dos SM com o valor dos switches
    List<String> nomesSM = []; //lista com os nomes dos SM
    List<bool> valoresSM = []; //lista com os valores dos SM

    SPListaSM.listaSM.forEach((key, value) {
      nomesSM.add(key);
      valoresSM.add(value);
    });

    debugMsgDev(nomesSM.toString(), tag: "switch");
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            child: DrawerHeader(
              child: Text(
                "Supermercados",
                style: TextStyle(fontSize: 20),
              ),
            ),
            height: 100,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            //switches com os nomes dos SM
            children: nomesSM
                .map((e) => new SwitchBuilder(
                    e, widget._reload, valoresSM[nomesSM.indexOf(e)]))
                .toList(),
          )
        ],
      ),
    );
  }
}

class SwitchBuilder extends StatefulWidget {
  //const SwitchBuilder({Key? key}) : super(key: key);

  String _nome;
  bool _valor;
  Function _reload;
  SwitchBuilder(this._nome, this._reload, this._valor);

  @override
  State<SwitchBuilder> createState() => _SwitchBuilderState();
}

class _SwitchBuilderState extends State<SwitchBuilder> {
  late bool isSwitched;

  void toggleSwitch(bool value) {
    setState(() {
      if (value) {
        SPListaSM().addSM(widget._nome);
      } else {
        SPListaSM().removeSM(widget._nome);
      }
    });
    widget._reload();
  }

  @override
  Widget build(BuildContext context) {
    bool isSwitched = widget._valor;
    debugMsgDev(widget._nome + " is " + isSwitched.toString(), tag: "switch");
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          child: Text(nameFormater(widget._nome)),
          decoration: BoxDecoration(
              border: Border.all(
            color: Colors.black,
            width: 1.0,
          )),
        ),
        Switch(
          onChanged: toggleSwitch,
          value: isSwitched,
        )
      ],
    );
  }
}
