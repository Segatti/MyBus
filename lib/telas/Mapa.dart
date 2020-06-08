import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mybus/model/Transporte.dart';

class Mapa extends StatefulWidget {
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> with WidgetsBindingObserver{
  //Configurações Gerais
  String _myPoint = "Eu -> Ponto: ∞";
  String _busPoint = "Ônibus(Oficial) -> Ponto: ∞";
  double _mySpeed = 1;
  bool _gps = false; //Ativa o floating action button
  bool _timeKey = false;
  String iconImage = "";
  String iconColor = "";
  Color _btnBus = Colors.black54;
  String _btnCriar = "Criar";
  bool _tipo = false;
  TextEditingController _nomeBus = TextEditingController();
  TextEditingController _rotaBus = TextEditingController();
  bool _transporteON = false;
  //Configurações Mapa
  MapboxMapController mapController;
  static final CameraPosition _kInitialPosition = const CameraPosition(target: LatLng(0, 0), zoom: 13.0);
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
  List<String> nomePontos = [
    "UNIFESSPA I",
    "UNIFESSPA II",
    "UNIFESSPA III",
    "Hospital Regional",
    "Bella Florença",
    "Shopping Pátio"
  ];
  List<LatLng> rotaGerada;
  List<Transporte> todosTransportes;
  Map<Symbol, Transporte> listaTransporte = new Map();

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
  void initState(){
    print("initState() - Inicio");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
    print("initState() - Fim");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("didChangeAppLifecycleState() - Inicio");
    if(state == AppLifecycleState.resumed){
      // user returned to our app
    }else if(state == AppLifecycleState.inactive){
      // app is inactive
    }else if(state == AppLifecycleState.paused){
      // user is about quit our app temporally
    }else if(state == AppLifecycleState.detached){
      // app suspended (not used in iOS)
    }
//    super.didChangeAppLifecycleState(state);
    print("didChangeAppLifecycleState() - Fim");
  }

  @override
  void dispose() {
    print("dispose - Inicio");
    mapController.clearLines();
    mapController.clearSymbols();
    WidgetsBinding.instance.removeObserver(this);
    print("dispose - Fim");
    super.dispose();
  }

  void _onMapCreated(MapboxMapController controller) {
    print("_onMapCreated() - Inicio");
    mapController = controller;
    _addMarcadorPonto(pontos, controller);
    _addTransporteListen(controller);
    print("_onMapCreated() - Fim");
  }
  
  void _addMarcadorPonto(List<LatLng> pontos, MapboxMapController controller) {
    print("_addMarcador() - Inicio");
    iconImage = "bus";
    for(int i = 0; i < pontos.length; i++){
      String nomeP = nomePontos[i];
      controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(
            pontos[i].latitude,
            pontos[i].longitude,
          ),
          iconImage: iconImage,
          iconSize: 1.5,
          iconAnchor: 'bottom',
          textField: nomeP,
          textAnchor: 'top'
        ),
      );
    }
    print("_addMarcador() - Fim");
  }

  void _addTransporteListen(MapboxMapController controller) async{
    print("_firebaseListen - Inicio");
    FirebaseAuth user = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await user.currentUser();
    String userID = usuarioLogado.uid;
    Firestore banco = Firestore.instance;
    banco.collection('transporte').snapshots().listen(
        (snapshot){
          snapshot.documentChanges.forEach(
              (documentChange) async{//As mudanças são em relação a variavel, não ao banco, ex: no inicio ele considera os dados que estão no banco como se fosse dados novos adicionados, pois são adicionado na varivel snapshot
                print("documentChange");
                if (documentChange.type == DocumentChangeType.added){
                  String id = documentChange.document.documentID;
                  if(id != userID){
                    Map<String, dynamic> dados = documentChange.document.data;
                    Transporte transporte = new Transporte(id, dados['nome'], dados['tipo'], dados['rota'], dados['lat'].toDouble(), dados['lng'].toDouble(), dados['status']);
                    Symbol symbol = await controller.addSymbol(
                      SymbolOptions(
                        geometry: LatLng(
                          transporte.lat,
                          transporte.lng,
                        ),
                      ),
                    );
                    listaTransporte.putIfAbsent(symbol, () => transporte);
                    print("document: ${documentChange.document.data} added");
                  }else{
                    print("Usuário criou um transporte!");
                  }
                } else if (documentChange.type == DocumentChangeType.modified) {
                  String id = documentChange.document.documentID;
                  if(id != userID){
                    Map<String, dynamic> dados = documentChange.document.data;
                    Transporte transporteAux = new Transporte(id, dados['nome'], dados['tipo'], dados['rota'], dados['lat'].toDouble(), dados['lng'].toDouble(), dados['status']);
                    print('status true');
                    listaTransporte.forEach((id, transporte){
                      print('forEach');
                      if(transporte.id == transporteAux.id){
                        print('id igual');
                        String iconText;
                        if(transporteAux.status){
                          if(transporteAux.tipo == 'bus'){
                            iconImage = 'car-15';
                            iconColor = '#000000';
                            iconText = transporteAux.nome;
                          }else{
                            iconImage = 'car-11';
                            iconColor = '#054f77';
                            iconText = transporteAux.nome;
                          }
                        }else{
                          if(transporteAux.tipo == 'bus'){
                            iconImage = 'none';
                            iconColor = '#000000';
                            iconText = '';
                          }else{
                            iconImage = 'none';
                            iconColor = '#054f77';
                            iconText = '';
                          }
                        }
                        controller.updateSymbol(id, SymbolOptions(
                            geometry: LatLng(
                              transporteAux.lat,
                              transporteAux.lng,
                            ),
                            iconImage: iconImage,
                            iconColor: iconColor,
                            iconSize: 1.5,
                            iconAnchor: 'bottom',
                            textField: iconText,
                            textAnchor: 'top'
                        ),);
                      }
                    });
                    print("document: ${documentChange.document.data} modified");
                  }else{
                    print("Usuário alterou um transporte!");
                  }
                } else if (documentChange.type == DocumentChangeType.removed){
                  String id = documentChange.document.documentID;
                  Map<String, dynamic> dados = documentChange.document.data;
                  Transporte transporteAux = new Transporte(id, dados['nome'], dados['tipo'], dados['rota'], dados['lat'].toDouble(), dados['lng'].toDouble(), dados['status']);
                  print(transporteAux);
                  listaTransporte.forEach((id, transporte){
                    print('forEach');
                    if(transporte.id == transporteAux.id){
                      print('id igual');
                      controller.removeSymbol(id);
                      listaTransporte.remove(id);
                    }
                  });
                  print("document: ${documentChange.document.data} removed");
                }
              }
          );
        }
    );
    print("_firebaseListen - Fim");
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
        if(_transporteON) _atualizarTransporte();
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
        if(_transporteON) _atualizarTransporte();
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
    if(rotaGerada != null) _apagaRota(rotaGerada);//Deletar desenho da rota se existir
    const String URL = 'https://api.mapbox.com/directions/v5/mapbox/walking/';
    const String access_token = 'pk.eyJ1IjoibXlidXNwcm9qZXRvIiwiYSI6ImNrOGk1cHJ5ajAyb28zbm82eGVyeTk5bGUifQ.IxCBJyDSNxbw3ulY0sIyfQ';
    String url = URL + minhaPosicao.longitude.toString() + ',' + minhaPosicao.latitude.toString() + ';' + destino.longitude.toString() + ',' + destino.latitude.toString() +
        '?steps=true' +
        '&access_token=' + access_token;
    print(url);
    http.Response result = await http.get(url);
    Map<String, dynamic> valor = jsonDecode(result.body);
    List<dynamic> rotaJSON = valor['routes'][0]['legs'][0]['steps'];
    List<dynamic> rotaAUX = new List();
    List<LatLng> pontosRota = new List();
    for(int i = 0; i < rotaJSON.length; i++) {
      rotaAUX.add(rotaJSON[i]['intersections']);
    }
    for(int i = 0; i < rotaAUX.length; i++) {
      for(int j = 0; j < rotaAUX[i].length; j++){
        LatLng aux = LatLng(rotaAUX[i][j]['location'][1], rotaAUX[i][j]['location'][0]);
        pontosRota.add(aux);
      }
    }
    rotaGerada = pontosRota;
    calculaTime(rotaGerada);
    _desenhaRota(rotaGerada);
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

  void _desenhaRota(List<LatLng> rotaGerada){
    print("_desenhaRota - Inicio");
    mapController.addLine(
      LineOptions(
        geometry: rotaGerada,
        lineColor: "#ff0000",
        lineWidth: 2.0,
        lineOpacity: 0.5,
      ),
    );
    setState(() {
      _scrollGesturesEnabled = false;//deixa false para dimuir processamento
    });
    print("_desenhaRota - Fim");
  }

  void _apagaRota(List<LatLng> rotaGerada){
    print("_apagaRota - Inicio");
    mapController.clearLines();
    print("_apagaRota - Fim");
  }

  void _criarTransporte(){
    print("_criarTransporte - Inicio");
    Transporte transporte = Transporte('', _nomeBus.text, (_tipo)?'taxi':'bus', _rotaBus.text, _myLocal.target.latitude, _myLocal.target.longitude, true);
    transporte.create();
    _transporteON = true;
    print("_criarTransporte - Fim");
  }

//  Future _lerTransporte() async{
//    print("_lerTransporte - Inicio");
//    Transporte transporte = Transporte('', '', '', '', 0.0, 0.0, false);
//    List<Transporte> transportes = await transporte.read();
//    print("_lerTransporte - Fim");
//    return transportes;
//  }

  void _atualizarTransporte(){
    print("_atualizarTransporte - Inicio");
    Transporte transporte = Transporte('', _nomeBus.text, (_tipo)?'taxi':'bus', _rotaBus.text, _myLocal.target.latitude, _myLocal.target.longitude, true);
    Map<String, dynamic> map = {
      "lat" : _myLocal.target.latitude,
      "lng" : _myLocal.target.longitude
    };
    transporte.update(map);
    print("_atualizarTransporte - Fim");
  }

  void _deletarTransporte(){
    print("_deletarTransporte - Inicio");
    Transporte transporte = Transporte('', '', '', '', 0, 0, false);
    _transporteON = false;
    transporte.delete();
    print("_deletarTransporte - Fim");
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
              Navigator.pushNamed(context, "/info");
            },
          ),
          IconButton(
            icon: Icon(Icons.access_time),
            onPressed: (){
              Navigator.pushNamed(context, "/horarios");
            },
          ),
          IconButton(
            icon: Icon(Icons.email),
            onPressed: (){
              Navigator.pushNamed(context, "/feedback");
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
//            Positioned(
//              top: 45,
//              left: 0,
//              right: 0,
//              child: Padding(
//                padding: EdgeInsets.all(10),
//                child: Container(
//                  height: 35,
//                  width: double.infinity,
//                  decoration: BoxDecoration(
//                      border: Border.all(color: Colors.grey),
//                      borderRadius: BorderRadius.circular(3),
//                      color: Colors.white
//                  ),
//                  child: Center(
//                    child:  Text(
//                        _busPoint
//                    )
//                  ),
//                ),
//              ),
//            ),
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
            child: Container(
              height: 60.0,
              width: 60.0,
              child: FittedBox(
                child: FloatingActionButton(
                  child: Icon(Icons.cancel),
                  backgroundColor: Colors.red,
                  onPressed: (){
                    _deletarTransporte();
                    setState(() {
                      _btnCriar = "Criar";
                      _gps = false;
                      _btnBus = Colors.black54;
                    });
                  },
                ),
              ),
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
                  backgroundColor: _btnBus,
                  onPressed: (){
                    showDialog(
                      context: context,
                      builder: (context){
                        return StatefulBuilder(
                          builder: (context, setState){
                            return AlertDialog(
                              title: Text(
                                  'Criar Transporte'
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    TextField(
                                      decoration: InputDecoration(
                                          labelText: 'Nome do transporte'
                                      ),
                                      controller: _nomeBus,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: <Widget>[
                                          Text("Ônibus"),
                                          Switch(
                                              value: _tipo,
                                              onChanged: (bool valor){
                                                setState(() {
                                                  _tipo = valor;
                                                });
                                              }
                                          ),
                                          Text("Taxi Lotação"),
                                        ],
                                      ),
                                    ),
                                    TextField(
                                      decoration: InputDecoration(
                                          labelText: 'Qual rota está fazendo?'
                                      ),
                                      controller: _rotaBus,
                                    ),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text("Cancelar"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                FlatButton(
                                  child: Text(_btnCriar),
                                  onPressed: (){
                                    //Salvar no banco de dados
                                    _criarTransporte();
                                    Navigator.pop(context);
                                    super.setState(() {
                                      _btnCriar = "Alterar";
                                      _gps = true;
                                      _btnBus = Colors.green;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    );
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
