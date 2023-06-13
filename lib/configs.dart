import 'dart:convert';

import 'package:comparador2/lib.dart';
import 'package:shared_preferences/shared_preferences.dart';

//
class SPListaSM {
  static Map<String, dynamic> listaSM =
      {}; //mapa final dos SM, usada nos switches

  //a ser usada na criacao da classe
  Future<void> buildListaSM() async {
    listaSM = await getListaSM();
    debugMsgDev(listaSM.toString(), tag: "configs");
  }

  //desativa o supermercado
  void removeSM(String sm) {
    listaSM[sm] = false;
    setListaSM(listaSM);
  }

  void addSM(String sm) {
    listaSM[sm] = true;
    setListaSM(listaSM);
  }

  //devolve o mapa de SM que o utilizador pre-definiu
  Future<Map<String, dynamic>> getListaSM() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance(); //carrega as definicoes guardadas
    //debugMsgDev(prefs.getStringList('listaSM').toString(), tag: "configs");

    Map<String, dynamic> listaSM;
    var tmp = prefs.getString('listaSM');
    if (tmp == null) {
      listaSM = {
        'auchan': true,
        'continente': true,
        'intermarche': true,
        'miniPreco': true,
        'pingoDoce': true,
      };

      //listaSM = ["continente", "pingoDoce", "auchan", "miniPreco", "intermarche"];
      setListaSM(listaSM);
    } else {
      listaSM = jsonDecode(tmp) as Map<String, dynamic>;
    }

    return listaSM;
  }

//define a lista de SM na shared memory
  Future<bool> setListaSM(Map<String, dynamic> listaSM) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(
        'listaSM', jsonEncode(listaSM)); //é necessário converter para json
  }
}

List<String> getNomesSM() {
  List<String> smAtivos = [];
  SPListaSM.listaSM.forEach((key, value) {
    if (value == true) {
      smAtivos.add(key);
    }
  });
  return smAtivos;
}
