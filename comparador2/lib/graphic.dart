import 'package:charts_flutter/flutter.dart' as charts;
import 'package:comparador2/lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class precosProdutosSeries {
  final double preco;
  final String date;

  precosProdutosSeries(this.preco, this.date);
}

class DataChartPage extends StatelessWidget {
  // const DataChartPage({Key? key}) : super(key: key);

  final String link;
  DataChartPage(this.link);

  /*
  final List<precosProdutosSeries> data = [
    precosProdutosSeries(1.3, "01/01/2020"),
    precosProdutosSeries(2.4, "01/02/2020"),
  ];

  */

  buildChart(data) {
    return SfCartesianChart(primaryXAxis: CategoryAxis(), series: <ChartSeries>[
      LineSeries<precosProdutosSeries, String>(
        dataSource: data,
        xValueMapper: (precosProdutosSeries x, _) => x.date,
        yValueMapper: (precosProdutosSeries y, _) => y.preco,
      )
    ]);
  }

  final List<precosProdutosSeries> data = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getPriceHistory(link),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var lista = snapshot.data as List<dynamic>;
            debugMsgDev(snapshot.data.toString(), tag: "DataChartPage");
            for (int i = 0; i < lista.length; i++) {
              data.add(precosProdutosSeries(lista[i][0], lista[i][1]));
            }
            return buildChart(data);
          }
          return Center(child: CircularProgressIndicator());
        });
  }
}
