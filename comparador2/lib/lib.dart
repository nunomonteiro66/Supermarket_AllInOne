import 'dart:io';

import 'package:comparador2/configs.dart';
//import 'package:comparador2/main%20-%20Copy.dart';
import 'package:comparador2/no_internet.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

//nota: limite=6
class SPListaSugestoes {
  static List<String> listaSugestoes = []; //sugestoes de pesquisa
  static int limit = 6; //limite de sugestoes

  //a ser usada na criacao da classe
  Future<void> buildListaSugestoes() async {
    listaSugestoes = await getListaSugestoes();
  }

  void removeSugestao(String sugestao) {
    listaSugestoes.remove(sugestao);
    setListaSugestoes(listaSugestoes);
  }

  void addSugestao(String sugestao) {
    //sugestao ja se encontra na lista, logo coloca-a como primeira e retira-a da posicao anterior
    if (listaSugestoes.contains(sugestao)) {
      listaSugestoes.remove(sugestao);
    }

    //limite alcancado, reset nas sugestoes
    if (listaSugestoes.length >= limit) {
      listaSugestoes = [];
    }
    listaSugestoes.insert(0, sugestao);

    setListaSugestoes(listaSugestoes);
  }

  //devolve a lista de sugestoes que o utilizador pre-definiu
  Future<List<String>> getListaSugestoes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    debugMsgDev(prefs.getStringList('listaSugestoes').toString(),
        tag: "configs");
    List<String> listaSugestoes;
    if (prefs.getStringList('listaSugestoes') == null) {
      listaSugestoes = [];
      setListaSugestoes(listaSugestoes);
    } else {
      listaSugestoes = prefs.getStringList('listaSugestoes') as List<String>;
    }
    return listaSugestoes;
  }

  //define a lista de Sugestoes na shared memory
  Future<bool> setListaSugestoes(List<String> listaSugestoes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList('listaSugestoes', listaSugestoes);
  }
}

void toasty(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 16.0);
}

class GlobalVariable {
  final MaterialColor card_color = Colors.red;
  static const api_url = ("http://192.168.1.175:8080");
  //static const api_url = ("http://127.0.0.1:8080");
  //static final api_url = ("http://mypythonapi.mywire.org:8080");
}

void debugMsgDev(String msg, {tag = "geral"}) {
  developer.log(msg, name: tag);
}

//param: map de parametros
//tem sempre de incluir os parametros todos (item e sm)
Future<List> readJson(var param) async {
  //final String response = await rootBundle.rootBundle.loadString('/assets/response.json');
  debugMsgDev("Tentar obter json", tag: "gettingInfo");
  var url = GlobalVariable.api_url + "/" + param['param1'] + "/";
  Map<String, String> headers = {
    'item': param['item'],
    'sm': param['sm'],
    'page': '0'
  };
  debugMsgDev("items: " + headers.toString(), tag: "gettingInfo");
  debugMsgDev("connecting to api...", tag: "gettingInfo");

  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    final data = await json.decode(utf8.decode(response.bodyBytes));
    debugMsgDev("json: " + data.toString(), tag: "gettingInfo");
    return List<dynamic>.from(data);
  } on Exception catch (_, e) {
    debugMsgDev("erro ao obter info", tag: "gettingInfo");
    return <dynamic>["-1"]; //erro
  }

  //{nomeSM, listProdutos}
}

Future<List> getSearchResults(var param) async {
  //final String response = await rootBundle.rootBundle.loadString('/assets/response.json');
  debugMsgDev("Tentar obter json", tag: "gettingSearch");
  var url = GlobalVariable.api_url + "/" + param['param1'] + "/";
  Map<String, String> headers = {
    'item': param['item'],
    'sm': param['sm'],
    'page': param['page'],
    'filter': param['filter']
  };
  debugMsgDev("items: " + headers.toString(), tag: "gettingSearch");
  debugMsgDev("connecting to api...", tag: "gettingSearch");
  debugMsgDev("url: " + url, tag: "gettingSearch");
  url = Uri.encodeFull(url);
  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    debugMsgDev("got response", tag: "gettingSearch");
    final data = await json.decode(utf8.decode(response.bodyBytes));
    return List<dynamic>.from(data);
  } on Exception catch (_, e) {
    debugMsgDev("erro ao obter info", tag: "gettingSearch");
    debugMsgDev("erro: " + e.toString(), tag: "gettingSearch");
    return <dynamic>["-1"]; //erro
  }

  //{nomeSM, listProdutos}
}

Future<List> getAll(var list_param) async {
  var lista_all = [];
  for (int i = 0; i < list_param.length; i++) {
    lista_all.add(await readJson(list_param[i]));
  }

  //verifica e remove os pedidos que falharam
  //isto significa que no index i tem [-1] (caso contrario teria um Map)
  var i = 0;
  while (i != lista_all.length) {
    debugMsgDev(lista_all[i][0].runtimeType.toString(), tag: "gettingInfo");
    if (lista_all[i][0].runtimeType == String) {
      debugMsgDev("a remover", tag: "gettingInfo");
      lista_all.removeAt(i);
    } else {
      i++;
    }
  }

  return lista_all;

  //[{nomeSM, listProdutos}, {nomeSM, listProdutos}, ...]
}

//obtem produtos equivalentes ao produto, mas de outros supermercados
Future<List> getComparisonProduct(
    var nome, var quantidade, var marca, var preco, var unidade) async {
  var url = GlobalVariable.api_url + "/equivalent/";

  nome = removeSpecialCharacters(nome);
  marca = removeSpecialCharacters(marca);

  Map<String, String> headers = {
    'nome': nome,
    'marca': marca,
    'quantidade': quantidade,
    'preco': preco.toString(),
    'unidade': unidade
  };

  debugMsgDev("param: $nome | $marca | $quantidade",
      tag: "getComparisonProduct");
  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    final data = await json.decode(utf8.decode(response.bodyBytes));
    var lista = List<dynamic>.from(data);
    lista.removeWhere((item) => item.toString() == '[]');

    debugMsgDev(lista.toString(), tag: "getComparisonProduct");

    return lista;
  } on Exception catch (_, e) {
    debugMsgDev("erro ao obter info", tag: "getComparisonProduct");
    return <dynamic>["-1"]; //erro
  }
}

//verifica se existe conexao e obtem as informacoes das SharedPreferences
Future<bool> checkConnection() async {
  try {
    await http.get(Uri.parse(GlobalVariable.api_url));
    await SPListaSM().buildListaSM();
  } on SocketException catch (e) {
    return false;
  }
  return true;
}

//"mistura" os produtos, isto é, insere o nome do SM em cada produto individualmente, e insere-os todos numa so lista<map>
List<Map> miscProducts(List<dynamic> lista) {
  List<Map> new_list = [];
  //para cada supermercado
  for (var i = 0; i < lista.length; i++) {
    var nome_sm = lista[i][0]['nomeSM'];
    var all_produtos = lista[i][0]['listaProdutos'];
    for (var n = 0; n < all_produtos.length; n++) {
      all_produtos[n]['nomeSM'] =
          nome_sm; //insere o nome do supermercado ao produto
      new_list.add(all_produtos[n]);
    }
  }
  return new_list;
}

class ImageNetworkBuilder extends StatelessWidget {
  final link;
  const ImageNetworkBuilder({Key? key, required this.link}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      link,
      loadingBuilder: ((context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: Container(color: Colors.grey),
        );
      }),
      errorBuilder:
          (BuildContext context, Object exception, StackTrace? stackTrace) {
        debugMsgDev("error", tag: "searchPageCardImg");
        return Image.asset('assets/images/error.png');
      },
    );
  }
}

//retorna o nome formatado dos nomes dos Supermercados
String nameFormater(String nomeSM) {
  switch (nomeSM) {
    case 'continente':
      return 'Continente';
    case 'pingoDoce':
      return 'Pingo Doce';
    case 'auchan':
      return 'Auchan';
    case 'miniPreco':
      return 'Mini Preço';
    case 'intermarche':
      return 'Intermarche';
    default:
      return nomeSM;
  }
}

MaterialColor getSMcolor(nomeSM) {
  debugMsgDev(nomeSM, tag: "getSMcolor");
  switch (nomeSM) {
    case 'Continente':
      return Colors.red;
    case 'Pingo Doce':
      return Colors.green;
    case 'Auchan':
      return Colors.blue;
    case 'Mini Preco':
      return Colors.orange;
    case 'Intermarche':
      return Colors.yellow;
    default:
      return Colors.red;
  }
}

int getRandomTag() {
  List<int> tags = [];
  while (true) {
    var rnd = Random().nextInt(1000000);
    if (!tags.contains(rnd)) {
      tags.add(rnd);
      return rnd;
    }
  }
}

Future<List> getPriceHistory(var link) async {
  Map<String, String> headers = {'link': link};
  var url = GlobalVariable.api_url + "/price_history/";
  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    final data = await json.decode(utf8.decode(response.bodyBytes));
    return List<dynamic>.from(data);
  } on Exception catch (_, e) {
    debugMsgDev("erro ao obter info", tag: "gettingSearch");
    return <dynamic>["-1"]; //erro
  }
}

String removeSpecialCharacters(String str) {
  str = str.replaceAll("ç", "c");
  str = str.replaceAll("ã", "a");
  str = str.replaceAll("á", "a");
  str = str.replaceAll("à", "a");
  str = str.replaceAll("é", "e");
  str = str.replaceAll("è", "e");
  str = str.replaceAll("í", "i");
  str = str.replaceAll("ì", "i");
  str = str.replaceAll("ó", "o");
  str = str.replaceAll("ò", "o");
  str = str.replaceAll("ú", "u");
  str = str.replaceAll("ù", "u");
  str = str.replaceAll("º", "");
  str = str.replaceAll("ª", "");
  str = str.replaceAll("é", "e");
  str = str.replaceAll("ê", "e");
  str = str.replaceAll("ô", "o");
  str = str.replaceAll("õ", "o");
  str = str.replaceAll("+", "");
  str = str.replaceAll("-", "");

  return str;
}
