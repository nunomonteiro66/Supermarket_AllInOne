import 'package:comparador2/lib.dart';
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import "package:google_maps_flutter/google_maps_flutter.dart";
import 'dart:math' show cos, sqrt, asin;
import 'package:permission_handler/permission_handler.dart';

class MapaHome extends StatelessWidget {
  //const MapaHome({Key? key}) : super(key: key);
  String nomeSM;
  MapaHome(this.nomeSM);

  @override
  Widget build(BuildContext context) {
    var heigh = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
        height: heigh,
        width: width,
        child: Scaffold(
          appBar: AppBar(title: Text("Distancia")),
          body: MapaBuilder(nomeSM),
        ));
  }
}

class MapaBuilder extends StatefulWidget {
  //const MapaBuilder({Key? key}) : super(key: key);

  String nomeSM;
  MapaBuilder(this.nomeSM);

  @override
  State<MapaBuilder> createState() => _MapaBuilderState();
}

class _MapaBuilderState extends State<MapaBuilder> {
  late Position _currentPosition;
  late Location _destinationPosition;

  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  late double distanciaTotal;

  late Set<Marker> markers;

  //String nomeSM = widget.nomeSM;

  //descobre a localizacao atual do dispositivo
  Future<bool> getCurrentLocation() async {
    Position position;
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPosition = position;
      return true;
    } catch (e) {
      //utilizador não permitiu o acesso
      return false;
    }
  }

  //localiza a posicao de um supermercado
  getPlace() async {
    var gp = GooglePlace("API-KEY");
    var result = await gp.search.getNearBySearch(
        Location(
            lat: _currentPosition.latitude, lng: _currentPosition.longitude),
        1500,
        keyword: widget.nomeSM);
    var resultados = result!.results as List<dynamic>;
    if (resultados.isNotEmpty) {
      return resultados[0].geometry.location;
    }
    return null;
  }

  //constroi os marcadores
  buildMarkers(Location dest) {
    Set<Marker> markers = {};

    Marker startMarker = Marker(
      markerId: MarkerId("start"),
      position: LatLng(_currentPosition.latitude, _currentPosition.longitude),
      infoWindow: InfoWindow(
        title: "Start",
        snippet: "This is the starting point",
      ),
      icon: BitmapDescriptor.defaultMarker,
    );

    Marker destinationMarker = Marker(
      markerId: MarkerId("destination"),
      position: LatLng(dest.lat!.toDouble(), dest.lng!.toDouble()),
      infoWindow: InfoWindow(
        title: "Destination",
        snippet: "This is the destination",
      ),
      icon: BitmapDescriptor.defaultMarker,
    );

    markers.add(startMarker);
    markers.add(destinationMarker);
    return markers;
  }

  //constroi as variaveis iniciais (a ser usado no Future Builder)
  Future<bool> buildVariables() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    //await Permission.locationWhenInUse.request(); //pede permissao para acessar a localizacao

    await getCurrentLocation(); //obter a posição atual do usuário
    if (getCurrentLocation() == false) {
      return false;
    }

    try {
      _destinationPosition = await getPlace(); //obter o local do supermercado
    } catch (e) {
      //nao foi possivel localizar o supermercado
      return false;
    }
    markers = buildMarkers(_destinationPosition); //construir os marcadores
    await linePoints(); //construir a linha
    //return markers;

    return true;
  }

  //constoi a linha
  linePoints() async {
    List<LatLng> polylineCoordinates = [];
    //Map<PolylineId, Polyline> polylines = {};

    polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        "API-KEY",
        PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
        PointLatLng(_destinationPosition.lat!.toDouble(),
            _destinationPosition.lng!.toDouble()));

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.red,
        points: polylineCoordinates,
        width: 3);

    polylines[id] = polyline;

    await calcularDistancia(polylineCoordinates);
  }

  //calcula a distancia entre duas coordenadas
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  //calcula a distancia total entre o usuário e o supermercado
  Future<void> calcularDistancia(List<LatLng> polylineCoordinates) async {
    double dt = 0.0;

    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      dt += _coordinateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }

    distanciaTotal = dt;
  }

  @override
  Widget build(BuildContext context) {
    debugMsgDev("starting to build mapa", tag: "mapa");
    return FutureBuilder(
        future: buildVariables(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == false) {
              //nao foi possivel localizar o supermercado
              return Center(
                child: Text(
                  "Não foi possível localizar o supermercado na sua região",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Stack(
              children: [mapaBuild(), safeAreaBuilder()],
            );
          }
          return Center(child: CircularProgressIndicator());
        });
  }

  //constroi o mapa
  mapaBuild() {
    late GoogleMapController mapController;
    return GoogleMap(
      polylines: Set<Polyline>.of(polylines.values),
      markers: Set<Marker>.from(markers),
      initialCameraPosition: CameraPosition(
          target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
          zoom: 15),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
      zoomGesturesEnabled: true,
      zoomControlsEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
        updateMapController(controller);
      },
    );
  }

  //atualiza a "camara" do mapa, de modo a mostrar ambos os pontos
  updateMapController(GoogleMapController controller) {
    double slat = _currentPosition.latitude.toDouble(); //latitude do usuário
    double slng = _currentPosition.longitude.toDouble(); //longitude do usuário
    double dlat =
        _destinationPosition.lat!.toDouble(); //latitude do supermercado
    double dlng =
        _destinationPosition.lng!.toDouble(); //longitude do supermercado

    double miny = (slat <= dlat) ? slat : dlat;
    double minx = (slng <= dlng) ? slng : dlng;
    double maxy = (slat <= dlat) ? dlat : slat;
    double maxx = (slng <= dlng) ? dlng : slng;

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          northeast: LatLng(maxy, maxx),
          southwest: LatLng(miny, minx),
        ),
        100.0,
      ),
    );
  }

  //menu no topo do mapa
  safeAreaBuilder() {
    return SafeArea(
      child: Visibility(
          visible: true,
          child: Container(
            width: double.infinity,
            height: 60,
            child: Card(
              elevation: 10,
              child: Column(
                children: [
                  Text(nameFormater(widget.nomeSM),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )),
                  Text(
                    "Distância: ${distanciaTotal.toStringAsFixed(2)} km",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
