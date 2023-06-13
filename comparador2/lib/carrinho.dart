import 'package:comparador2/lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:comparador2/comparador_final.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

var lista_produtos = [];

//produto = Map
//verifica se o produto já existe na lista_produtos, e adiciona-o caso ainda não
void addProdutoCarrinho(var produto, var sm) {
  if (lista_produtos.length == 0) {
    debugMsgDev("empty", tag: "carrinho");
    lista_produtos.add(produto);
    toasty("Produto adicionado ao carrinho");
  } else {
    for (int i = 0; i < lista_produtos.length; i++) {
      if (lista_produtos[i]['link'] == produto['link']) {
        debugMsgDev("iguais", tag: "carrinho");
        toasty("Produto já foi adicionado");
        return;
      }
    }
    toasty("Produto adicionado ao carrinho");
    lista_produtos.add(produto);
  }
}

class slideTest extends StatefulWidget {
  const slideTest({Key? key}) : super(key: key);

  @override
  State<slideTest> createState() => _slideTestState();
}

class _slideTestState extends State<slideTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Carrinho"),
        ),
        body: ListView(
          children: [
            Slidable(
              startActionPane: ActionPane(
                motion: ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: null,
                    backgroundColor: Colors.pink,
                    icon: Icons.delete,
                  )
                ],
              ),
              endActionPane: ActionPane(
                motion: ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: null,
                    backgroundColor: Colors.pink,
                    icon: Icons.delete,
                  )
                ],
              ),
              child: Container(child: Text("asdsadasd")),
            ),
          ],
        ));
  }
}

//main builder
class carrinho extends StatefulWidget {
  @override
  State<carrinho> createState() => _carrinhoState();
}

class _carrinhoState extends State<carrinho> {
  void _update(var produto) {
    setState(() {
      lista_produtos.remove(produto);
    });
  }

  @override
  Widget build(BuildContext context) {
    debugMsgDev(lista_produtos.length.toString(), tag: "carrinho");
    var index = -1;

    if (lista_produtos.length == 0) {
      return emptyCartBuilder();
    }

    ActionPane _ActionPane(produto) {
      return ActionPane(
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (BuildContext context) {
              setState(() {
                debugMsgDev("a remover produto", tag: "carrinho");
                lista_produtos.remove(produto);
              });
            },
            backgroundColor: Colors.pink,
            icon: Icons.delete,
          )
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Carrinho"),
      ),
      body: ListView(
        children: [
          //column para o butao no final
          Column(
              children: lista_produtos.map((produto) {
            index++;
            return Slidable(
                startActionPane: _ActionPane(produto),
                endActionPane: _ActionPane(produto),
                child: Card(
                    elevation: 10,
                    //construtor de cada produto
                    child: produtoCard(produto)
                    //child: ProductRow(produto: produto, index: index),
                    ));
          }).toList()),

          //butao de comparar
          CompararProdutosButton(lista_produtos: lista_produtos)
        ],
      ),
    );

    return Scaffold(
        appBar: AppBar(title: Text("Carrinho")),
        body: ListView(children: [
          Column(
            children: lista_produtos.map((produto) {
              index++;
              return Card(
                elevation: 10,
                child: ProductRow(produto: produto, index: index),
              );
            }).toList(),
          ),
          CompararProdutosButton(lista_produtos: lista_produtos)
        ])

        /*
      body: ListView.builder(
          itemCount: lista_produtos.length,
          itemBuilder: (BuildContext context, int index) {
            return ProductRow(
              produto: lista_produtos[index],
              update: _update,
              index: index,
            );
          }),
    */
        );
  }
}

class ProductRow extends StatelessWidget {
  final produto;
  final index; //hero tag
  const ProductRow({Key? key, required this.produto, required this.index})
      : super(key: key);

  final double bigLetterSize = 20;
  final double medLetterSize = 15;
  final double smallLetterSize = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.topLeft,
              child: Image.network(produto['img']),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: Text(produto['nome'],
                      style: TextStyle(fontSize: bigLetterSize)),
                ),
                Expanded(
                  child: Text(
                    produto['marca'],
                    style: TextStyle(fontSize: medLetterSize),
                  ),
                ),
                Expanded(
                    child: Text(
                  produto['nome'],
                  style: TextStyle(fontSize: medLetterSize),
                )),
                Expanded(
                  child: Text(
                    produto['quantidade'],
                    style: TextStyle(fontSize: smallLetterSize),
                  ),
                ),
                Expanded(
                  child: Text(
                    produto['preco'].toString(),
                    style: TextStyle(fontSize: medLetterSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CompararProdutosButton extends StatelessWidget {
  final lista_produtos;

  CompararProdutosButton({Key? key, required this.lista_produtos})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text("Obter melhor preço"),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => (ComparadorFinalMain(
                    lista_produtos: lista_produtos,
                  ))),
        );
      },
    );
  }
}

class emptyCartBuilder extends StatelessWidget {
  const emptyCartBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carrinho")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(image: AssetImage("assets/images/empty_cart.webp")),
          Container(
            height: 20,
          ),
          Text("Carrinho vazio\nPor favor adicione itens",
              style: TextStyle(fontSize: 20)),
          Spacer()
        ],
      ),
    );
  }
}

class produtoCard extends StatelessWidget {
  //const produtoCard({ Key? key }) : super(key: key);
  final produto;
  produtoCard(this.produto);

  final double bigLetterSize = 20;
  final double medLetterSize = 15;
  final double smallLetterSize = 10;

  @override
  Widget build(BuildContext context) {
    var nomeSM = nameFormater(produto['nomeSM']);
    return Container(
      height: 200,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: ImageNetworkBuilder(
                link: produto['img'],
              )),

          //coluna com as informacoes do produto
          Expanded(
              child: Column(
            children: [
              Expanded(
                  child: Text(
                nomeSM,
                style: TextStyle(
                    fontSize: bigLetterSize, color: getSMcolor(nomeSM)),
              )),
              Expanded(
                  child: Text(
                produto['marca'].toString(),
                style: TextStyle(fontSize: bigLetterSize),
              )),
              Expanded(
                  child: Text(
                produto['nome'].toString(),
                style: TextStyle(fontSize: medLetterSize),
                textAlign: TextAlign.center,
              )),
              Expanded(
                  child: Text(
                produto['quantidade'].toString() +
                    " " +
                    produto['quantidade_u_m'].toString(),
                style: TextStyle(fontSize: bigLetterSize),
              )),
              Expanded(
                  child: Text(
                produto['preco'].toString() + "€",
                style: TextStyle(fontSize: bigLetterSize),
              )),
            ],
          ))
        ],
      ),
    );
  }
}
