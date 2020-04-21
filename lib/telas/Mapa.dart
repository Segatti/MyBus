import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class Mapa extends StatefulWidget {
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  //Configurações Gerais
  String _myPoint = "Eu -> Ponto: ∞";
  String _busPoint = "Ônibus(Oficial) -> Ponto: ∞";
  double _mySpeed = 1;
  bool _gps = false; //Ativa o floating action button
  bool _timeKey = false;
  String iconImage = "bus";
  //Configurações Mapa
  MapboxMapController mapController;
  static final CameraPosition _kInitialPosition = const CameraPosition(target: LatLng(0, 0), zoom: 17.0);
  String _styleString = MapboxStyles.MAPBOX_STREETS;
  MyLocationTrackingMode _myLocationTrackingMode = MyLocationTrackingMode.Tracking;
  CameraTargetBounds _cameraTargetBounds = CameraTargetBounds.unbounded;
  MinMaxZoomPreference _minMaxZoomPreference = MinMaxZoomPreference.unbounded;
  bool _compassEnabled = true;
  bool _zoomGesturesEnabled = true;
  bool _myLocationEnabled = true;
  bool _rotateGesturesEnabled = false;
  bool _scrollGesturesEnabled = false;
  bool _tiltGesturesEnabled = false;
  CameraPosition _myLocal = _kInitialPosition;
  //Todos os pontos de parada de ônibus
  List<LatLng> pontos = [
    new LatLng(-5.350206, -49.093249),//Campus I
    new LatLng(-5.334712, -49.087594),//Campus II
    new LatLng(-5.365898, -49.024760),//Campus III
    new LatLng(-5.357781, -49.079264),//Regional
    new LatLng(-5.371145, -49.041989),//Bella Florença
    new LatLng(-5.357330, -49.086745) //Shopping
  ];
  List<LatLng> rotaGerada;

  //car-11 = azul = taxi lotação(comunidade)
  //car-11 = preto = ônibus(comunidade)
  //car-15 = vermelho = ônibus(Oficial)

//  $pontos[] = array(-5.350206, -49.093249);//Campus I
//  $pontos[] = array(-5.334712, -49.087594);//Campus II
//  $pontos[] = array(-5.357781, -49.079264);//Regional
//  $pontos[] = array(-5.371145, -49.041989);//Bella Florença
//  $pontos[] = array(-5.365898, -49.024760);//Campus III
//  $pontos[] = array(-5.371145, -49.041989);//Bella Florença
//  $pontos[] = array(-5.357330, -49.086745);//Shopping

  @override
  void initState() {
    print("initState() - Inicio");
    super.initState();
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
    print("initState() - Fim");
  }

  void _onMapCreated(MapboxMapController controller) {
    print("_onMapCreated() - Inicio");
    mapController = controller;
    _addMarcador(pontos, controller);
    print("_onMapCreated() - Fim");
  }
  
  void _addMarcador(List<LatLng> pontos, MapboxMapController controller){
    print("_addMarcador() - Inicio");
    for(int i = 0; i < pontos.length; i++){
      controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(
            pontos[i].latitude,
            pontos[i].longitude,
          ),
          iconImage: iconImage,
          iconSize: 1.5,
        ),
      );
    }
    print("_addMarcador() - Fim");
  }

  void _recuperaUltimaLocalizacaoConhecida() async {
    print("_recuperaUltimaLocalizacaoConhecida() - Inicio");
    Position position = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      if(position != null){
        _myLocal = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15
        );
      }
    });
    print("_recuperaUltimaLocalizacaoConhecida() - Fim");
  }

  void _adicionarListenerLocalizacao(){
    print("_adicionarListenerLocalizacao() - Inicio");
    var geolocator = Geolocator();
    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
    //Função responsavel por atualizar minha localização
    geolocator.getPositionStream(locationOptions).listen((Position position){
      setState(() {
        if(_timeKey) calculaTime(rotaGerada);
        _mySpeed = position.speed;
        _myLocal = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15
        );
      });
    });
    print("_adicionarListenerLocalizacao() - Fim");
  }

  void _buscarPonto(){
    print("_buscarPonto() - Inicio");
    LatLng minhaPosicao = new LatLng(_myLocal.target.latitude, _myLocal.target.longitude);
    LatLng pontoProximo = _encontrarParadaProxima();
    LatLng northeast;
    LatLng southwest;
    if(minhaPosicao.latitude <= pontoProximo.latitude){
      northeast = new LatLng(pontoProximo.latitude, pontoProximo.longitude);
      southwest = new LatLng(minhaPosicao.latitude, minhaPosicao.longitude);
    }else{
      northeast = new LatLng(minhaPosicao.latitude, minhaPosicao.longitude);
      southwest = new LatLng(pontoProximo.latitude, pontoProximo.longitude);
    }
    LatLngBounds zoomPontos = new LatLngBounds(
      northeast: northeast,
      southwest: southwest,
    );
    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(zoomPontos, 25),
    ).then((result) async{
        final _origin = Location(name: "Minha Localização", latitude: minhaPosicao.latitude, longitude: minhaPosicao.longitude);
        final _destination = Location(name: "Destino", latitude: pontoProximo.latitude, longitude: pontoProximo.longitude);
        _gerarRota(_origin, _destination);
      }
    );
    print("_buscarPonto() - Fim");
  }

  LatLng _encontrarParadaProxima(){
    print("_encontrarParadaProxima() - Inicio");
    _recuperaUltimaLocalizacaoConhecida();
    LatLng minhaPosicao = new LatLng(_myLocal.target.latitude, _myLocal.target.longitude);
    double distancia = 999999999999;
    int pontoProximo;
    for(int i = 0; i < pontos.length; i++){
      if(distancia > _calculaDistancia(minhaPosicao, pontos[i])){
        distancia = _calculaDistancia(minhaPosicao, pontos[i]);
        pontoProximo = i;
      }
    }
    print("_encontrarParadaProxima() - Fim");
    return pontos[pontoProximo];
  }

  void _gerarRota(Location minhaPosicao,Location destino) async {
    print("_gerarRota - Inicio");
    const String URL = 'https://api.mapbox.com/directions/v5/mapbox/walking/';
    const String access_token = 'pk.eyJ1IjoibXlidXNwcm9qZXRvIiwiYSI6ImNrOGk1cHJ5ajAyb28zbm82eGVyeTk5bGUifQ.IxCBJyDSNxbw3ulY0sIyfQ';
    String url = URL + minhaPosicao.longitude.toString() + ',' + minhaPosicao.latitude.toString() + ';' + destino.longitude.toString() + ',' + destino.latitude.toString() +
        '?steps=true' +
        '&access_token=' + access_token;
    http.Response result = await http.get(url);
    Map<String, dynamic> valor = jsonDecode(result.body);
    List<dynamic> rotaJSON = valor['routes'][0]['legs'][0]['steps'];
    List<LatLng> pontosRota = new List();
    for(int i = 0; i < rotaJSON.length; i++){
      LatLng aux = LatLng(rotaJSON[i]['maneuver']['location'][1], rotaJSON[i]['maneuver']['location'][0]);
      pontosRota.add(aux);
    }
    rotaGerada = pontosRota;
    calculaTime(rotaGerada);
    print("_gerarRota - Fim");
  }

  void calculaTime(List<LatLng> pontosRota){
    print("calculaTime - Inicio");
    double distanciaTotal = 0;
    for(int i = 0; i < pontosRota.length; i++){
      if(i == 0) continue;
      distanciaTotal += _calculaDistancia(pontosRota[(i-1)], pontosRota[i]);
    }
    print("Distancia total é: " + distanciaTotal.toString());
    double speedKH = _mySpeed;
    if(speedKH < 0.2){
      setState(() {
        _timeKey = true;
        _myPoint = "Eu -> Ponto: Você está parado!";
      });
    }else{
      int minutos = (((distanciaTotal*1000)/speedKH)/60).round();
      if(minutos <= 1){
        setState(() {
          _timeKey = true;
          _myPoint = "Eu -> Ponto: menos de 1 minuto";
        });
      }else{
        setState(() {
          _timeKey = true;
          _myPoint = "Eu -> Ponto: "+ minutos.toString() +" minutos";
        });
      }
    }
    print("calculaTime - Fim");
  }

  double _calculaDistancia(LatLng origin, LatLng destiny){
    print("_calculaDistancia - Inicio");
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((destiny.latitude - origin.latitude) * p)/2 +
        c(origin.latitude * p) * c(destiny.latitude * p) *
            (1 - c((destiny.longitude - origin.longitude) * p))/2;
    print("_calculaDistancia - Fim");
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MyBus"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: (){

            },
          ),
          IconButton(
            icon: Icon(Icons.access_time),
            onPressed: (){

            },
          ),
          IconButton(
            icon: Icon(Icons.email),
            onPressed: (){

            },
          ),
        ],
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            MapboxMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _kInitialPosition,
              trackCameraPosition: true,
              compassEnabled: _compassEnabled,
              cameraTargetBounds: _cameraTargetBounds,
              minMaxZoomPreference: _minMaxZoomPreference,
              styleString: _styleString,
              rotateGesturesEnabled: _rotateGesturesEnabled,
              scrollGesturesEnabled: _scrollGesturesEnabled,
              tiltGesturesEnabled: _tiltGesturesEnabled,
              zoomGesturesEnabled: _zoomGesturesEnabled,
              myLocationEnabled: _myLocationEnabled,
              myLocationTrackingMode: _myLocationTrackingMode,
              myLocationRenderMode: MyLocationRenderMode.GPS,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Container(
                  height: 35,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white
                  ),
                  child: Center(
                    child: Text(
                      _myPoint,
                      textAlign: TextAlign.center,
                    ),
                  )
                ),
              ),
            ),
            Positioned(
              top: 45,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Container(
                  height: 35,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white
                  ),
                  child: Center(
                    child:  Text(
                        _busPoint
                    )
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Padding(
                padding: Platform.isIOS
                    ? EdgeInsets.fromLTRB(20, 10, 20, 25)
                    : EdgeInsets.all(10),
                child: RaisedButton(
                    child: Text(
                      "Buscar Ponto de Ônibus",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    color: Color(0xff1ebbd8),
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    onPressed: (){
                      _buscarPonto();
                    }
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if(_gps) Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              child: Icon(Icons.gps_fixed),
              onPressed: (){
                setState(() {
                  _gps = false;
                });
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: Container(
              height: 70.0,
              width: 70.0,
              child: FittedBox(
                child: FloatingActionButton(
                  child: Icon(Icons.directions_bus),
                  onPressed: (){
                    setState(() {
                      _gps = true;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
