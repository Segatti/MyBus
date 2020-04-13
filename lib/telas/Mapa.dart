import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';

class Mapa extends StatefulWidget {
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  _MapaState();

  static final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 11.0,
  );

  MapboxMapController mapController;
  CameraPosition _position = _kInitialPosition;
  bool _isMoving = false;
  bool _compassEnabled = true;
  CameraTargetBounds _cameraTargetBounds = CameraTargetBounds.unbounded;
  MinMaxZoomPreference _minMaxZoomPreference = MinMaxZoomPreference.unbounded;
  String _styleString = MapboxStyles.MAPBOX_STREETS;
  bool _rotateGesturesEnabled = false;
  bool _scrollGesturesEnabled = false;
  bool _tiltGesturesEnabled = false;
  bool _zoomGesturesEnabled = true;
  bool _myLocationEnabled = true;
  MyLocationTrackingMode _myLocationTrackingMode = MyLocationTrackingMode.Tracking;
  CameraPosition _posicaoCamera = new CameraPosition(
    //bearing: 270.0,
    target: LatLng(0, 0),
    //tilt: 30.0,
    zoom: 17.0,
  );
  String iconImage = "bus";
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

  List<LatLng> pontos = [
    new LatLng(-5.350206, -49.093249),//Campus I
    new LatLng(-5.334712, -49.087594),//Campus II
    new LatLng(-5.365898, -49.024760),//Campus III
    new LatLng(-5.357781, -49.079264),//Regional
    new LatLng(-5.371145, -49.041989),//Bella Florença
    new LatLng(-5.357330, -49.086745) //Shopping
  ];

  static final LatLng center = LatLng(0, 0);

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    mapController.addListener(_onMapChanged);
    _extractMapInfo();

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
  }

  void _onMapChanged() {
    setState(() {
      _extractMapInfo();
    });
  }

  void _extractMapInfo() {
    _position = mapController.cameraPosition;
    _isMoving = mapController.isCameraMoving;
  }

  @override
  void dispose() {
    mapController.removeListener(_onMapChanged);
    super.dispose();
  }

  _adicionarListenerLocalizacao(){

    var geolocator = Geolocator();
    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10
    );

    geolocator.getPositionStream( locationOptions ).listen((Position position){

      _posicaoCamera = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15
      );

      //_movimentarCamera( _posicaoCamera );

    });

  }

  _recuperaUltimaLocalizacaoConhecida() async {

    Position position = await Geolocator()
        .getLastKnownPosition( desiredAccuracy: LocationAccuracy.high );

    setState(() {
      if( position != null ){
        _posicaoCamera = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 19
        );

        //_movimentarCamera( _posicaoCamera );

      }
    });

  }

  _movimentarCamera( CameraPosition cameraPosition ) async {

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        cameraPosition
      ),
    ).then((result)=>print("mapController.animateCamera()"));

  }

  _calculaDistancia(LatLng A, LatLng B){
    double catetoLat = (A.latitude - B.latitude).abs();
    double catetoLng = (A.longitude - B.longitude).abs();
    return sqrt(pow(catetoLat, 2) + pow(catetoLng, 2));
  }

  LatLng _encontrarParadaProxima(){
    _recuperaUltimaLocalizacaoConhecida();
    LatLng minhaPosicao = new LatLng(_posicaoCamera.target.latitude, _posicaoCamera.target.longitude);
    double distancia = 999999999999;
    int pontoProximo;
    for(int i = 0; i < pontos.length; i++){
      if(distancia > _calculaDistancia(minhaPosicao, pontos[i])){
        distancia = _calculaDistancia(minhaPosicao, pontos[i]);
        pontoProximo = i;
      }
    }
    return pontos[pontoProximo];
  }

  _buscarPonto(){
    print("BuscarPonto()");
    LatLng minhaPosicao = new LatLng(_posicaoCamera.target.latitude, _posicaoCamera.target.longitude);
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
    LatLngBounds pontos = new LatLngBounds(
      northeast: northeast,
      southwest: southwest,
    );
    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
          pontos,
          20
      ),
    ).then(
      (result)=>print("mapController.animateCamera()")
    );
    print("BuscarPonto() - FIM");
  }

  @override
  void initState() {
    super.initState();
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
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
                      "Eu -> Ponto: ∞",
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
                        "Ônibus(Oficial) -> Ponto: ∞"
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 65),
        child: FloatingActionButton(
          child: Icon(Icons.directions_bus),
          onPressed: (){

          },
        ),
      ),
    );
  }
}
