import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mybus/model/PontoBus.dart';
import 'package:mybus/model/Transporte.dart';

class Mapa extends StatefulWidget {
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> with WidgetsBindingObserver{
  //Configurações Gerais
  String _myPoint = "Eu -> Ponto: ∞";
  //String _busPoint = "Ônibus(Oficial) -> Ponto: ∞";
  GeoPoint _meuGeoPoint;
  double _meuSpeed = 1;
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
  Map<String, dynamic> marcadorParada = new Map();
  Map<String, dynamic> marcadorSymbolParada = new Map();
  Map<String, dynamic> marcadorOnibus = new Map();
  Map<String, dynamic> marcadorSymbolOnibus = new Map();
  Transporte _busMainFila;
  Transporte _meuTransporte;
//    new LatLng(-5.350206, -49.093249),//Campus I
//    new LatLng(-5.334712, -49.087594),//Campus II
//    new LatLng(-5.365898, -49.024760),//Campus III
//    new LatLng(-5.357781, -49.079264),//Regional
//    new LatLng(-5.371145, -49.041989),//Bella Florença
//    new LatLng(-5.357330, -49.086745) //Shopping

//  List<String> nomePontos = [
//    "UNIFESSPA I",
//    "UNIFESSPA II",
//    "UNIFESSPA III",
//    "Hospital Regional",
//    "Bella Florença",
//    "Shopping Pátio"
//  ];
  List<GeoPoint> rotaGerada;
  List<Transporte> todosTransportes;
  Map<Symbol, dynamic> listaTransporte = new Map();
  Symbol _selectedSymbol;

  TextEditingController _auxT = TextEditingController();
  TextEditingController _auxRota = TextEditingController();
  TextEditingController _auxTipo = TextEditingController();
  bool _infoTransporteON;
  bool _filaEspera;
  bool _busON;

  IconData _iconGPS = Icons.gps_fixed;
  Color _colorGPS = Colors.blue;

  //Geral//

  //Ponto de ônibus//
  TextEditingController _nomePointBus = TextEditingController();
  TextEditingController _descricaoPointBus = TextEditingController();

  PontoBus _pontoBusMain = PontoBus();
  String txtPontoBus = "Criar Ponto de Ônibus";
  String btnPontoBus = 'Criar';
  bool pontoBusON = false;

  //Ônibus//
  bool changeBus = false;


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
      if(_transporteON){
        _deletarTransporte();
        setState(() {
          _btnCriar = "Criar";
          _gps = false;
          _btnBus = Colors.black54;
        });
      }
    }else if(state == AppLifecycleState.paused){
      // user is about quit our app temporally
    }else if(state == AppLifecycleState.detached){
      // app suspended (not used in iOS)
      if(_transporteON){
        _deletarTransporte();
        setState(() {
          _btnCriar = "Criar";
          _gps = false;
          _btnBus = Colors.black54;
        });
      }
    }
//    super.didChangeAppLifecycleState(state);
    print("didChangeAppLifecycleState() - Fim");
  }

  @override
  void dispose() {
    print("dispose - Inicio");
    _deletarTransporte();
    mapController?.onSymbolTapped?.remove(_onSymbolTapped);
    mapController.clearLines();
    mapController.clearSymbols();
    WidgetsBinding.instance.removeObserver(this);
    print("dispose - Fim");
    super.dispose();
  }

  void _onMapCreated(MapboxMapController controller) {
    print("_onMapCreated() - Inicio");
    mapController = controller;
    mapController.onSymbolTapped.add(_onSymbolTapped);
    _addMarcadorPontoListen(marcadorParada, marcadorSymbolParada, controller);
    _addMarcadorTransporteListen(marcadorOnibus, marcadorSymbolOnibus, controller);
    print("_onMapCreated() - Fim");
  }

  void _addMarcadorPontoListen(Map<String, dynamic> dadosListen, Map<String, dynamic> dadosSymbol, MapboxMapController controller) {
    print("_addMarcadorPontoListen() - Inicio");
    Firestore firestore = Firestore.instance;
    firestore.collection('ponto_onibus').snapshots().listen((snapshot) {
      snapshot.documentChanges.forEach((documentChange) async {
        if(documentChange.type == DocumentChangeType.added){//Registro Adicionado
          String id = documentChange.document.documentID;
          dadosListen.putIfAbsent(id, () => documentChange.document.data);
          iconImage = "bus";
          Symbol symbol = await controller.addSymbol(
            SymbolOptions(
              geometry: LatLng(
                dadosListen[id]['geoPoint'].latitude,
                dadosListen[id]['geoPoint'].longitude,
              ),
              iconImage: iconImage,
              iconSize: 1.3,
              iconAnchor: 'bottom',
              textField: dadosListen[id]['nome'],
              textAnchor: 'top',
            ),
          );
          dadosSymbol.putIfAbsent(id, () => symbol);
          print("Dado adicionado a lista! ${dadosListen[id]}");
        }else if(documentChange.type == DocumentChangeType.modified){//Registro Atualizado
          String id = documentChange.document.documentID;
          dadosListen[id] = documentChange.document.data;
          await controller.updateSymbol(
            dadosSymbol[id],
            SymbolOptions(
              textField: dadosListen[id]['nome'],
            ),
          );
          print("Dado atualizado na lista! ${dadosListen[id]}");
        }else if(documentChange.type == DocumentChangeType.removed){//Registro Removido
          String id = documentChange.document.documentID;
          await controller.removeSymbol(dadosSymbol[id]);
          dadosListen.remove(id);
          dadosSymbol.remove(id);
          print("Dado removido da lista! ${documentChange.document.data}");
        }
      });
    });
    print("_addMarcador() - Fim");
  }

  void _onSymbolTapped(Symbol symbol) {
    print("_onSymbolTapped - Inicio");
    if (_selectedSymbol != null) {
      _updateSelectedSymbol(
        const SymbolOptions(iconSize: 1.3),
      );
    }
    setState(() {
      _selectedSymbol = symbol;
    });
    _updateSelectedSymbol(
      SymbolOptions(
        iconSize: 1.6,
      ),
    );
    if(_selectedSymbol.options.iconImage != ''){
      if(_selectedSymbol.options.iconImage == 'bus'){//Caso clique no ponto de ônibus para obter mais informações
        marcadorSymbolParada.forEach((id, symbol) {
          if(_selectedSymbol.id == symbol.id){
            setState(() {
              _pontoBusMain.id = id;
              _nomePointBus.text = marcadorParada[id]['nome'];
              _descricaoPointBus.text = marcadorParada[id]['descricao'];
            });
            showDialog(
                context: context,
                builder: (context){
                  return StatefulBuilder(
                    builder: (context, setState){
                      return AlertDialog(
                        title: Text(
                            "Alterar Ponto de Ônibus"
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TextField(
                                decoration: InputDecoration(
                                    labelText: 'Nome do local'
                                ),
                                controller: _nomePointBus,
                              ),
                              TextField(
                                decoration: InputDecoration(
                                    labelText: 'Descrição do local ou ponto de referência'
                                ),
                                controller: _descricaoPointBus,
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text('Criar Transporte'),
                            onPressed: () {
                              Navigator.pop(context);
                              String destino = "${_nomePointBus.text} - ${_descricaoPointBus.text}";
                              criarTransporteComPonto(destino, true);
                            },
                          ),
                          FlatButton(
                            child: Text('Excluir'),
                            onPressed: () {
                              _deletarPontoBus(_pontoBusMain.id);
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                            child: Text('Salvar'),
                            onPressed: (){
                              //Salvar no banco de dados
                              _atualizarPontoBus(_pontoBusMain.id);
                              Navigator.pop(context);
                              super.setState(() {

                              });
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
            );
          }
        });
      }else{//Caso clique no transporte para obter mais informações
        marcadorSymbolOnibus.forEach((id, symbol) {
          if(_selectedSymbol.id == symbol.id){
            setState(() {
              _auxTipo.text = (marcadorOnibus[id]['tipo'] == 'bus')?'Ônibus':'Taxi-Lotação';
              _auxT.text = marcadorOnibus[id]['nome'];
              _auxRota.text = marcadorOnibus[id]['rota'];
              _infoTransporteON = true;
            });
            showDialog(
                context: context,
                builder: (context){
                  return StatefulBuilder(
                    builder: (context, setState){
                      return AlertDialog(
                        title: Text(
                            'Transporte Info'
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TextField(
                                decoration: InputDecoration(
                                    labelText: "Nome do Transporte"
                                ),
                                controller: _auxT,
                                readOnly: true,
                              ),
                              TextField(
                                decoration: InputDecoration(
                                    labelText: "Tipo do Transporte"
                                ),
                                controller: _auxTipo,
                                readOnly: true,
                              ),
                              TextField(
                                decoration: InputDecoration(
                                    labelText: 'Qual rota está fazendo?'
                                ),
                                controller: _auxRota,
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Fechar"),
                            onPressed: (){
                              _infoTransporteON = false;
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
            );
          }
        });
      }
      print("_onSymbolTapped - Fim");
    }
  }

  void _updateSelectedSymbol(SymbolOptions changes) {
    mapController.updateSymbol(_selectedSymbol, changes);
  }

  void _addMarcadorTransporteListen(Map<String, dynamic> dadosListen, Map<String, dynamic> dadosSymbol, MapboxMapController controller) {
    print("_addMarcador() - Inicio");
    Firestore firestore = Firestore.instance;
    firestore.collection('transporte').snapshots().listen((snapshot) {
      snapshot.documentChanges.forEach((documentChange) async {
        if(documentChange.type == DocumentChangeType.added){//Registro Adicionado
          String id = documentChange.document.documentID;
          dadosListen.putIfAbsent(id, () => documentChange.document.data);
          iconImage = "";
          Symbol symbol = await controller.addSymbol(
            SymbolOptions(
              geometry: LatLng(
                dadosListen[id]['geoPoint'].latitude,
                dadosListen[id]['geoPoint'].longitude,
              ),
              iconImage: iconImage,
              iconSize: 1.3,
              iconAnchor: 'bottom',
              //textField: dadosListen[id]['nome'],//Lembrar de comentar isso aqui----------------------------------------
              textAnchor: 'top',
            ),
          );
          dadosSymbol.putIfAbsent(id, () => symbol);
          print("Dado adicionado a lista! ${dadosListen[id]}");
        }else if(documentChange.type == DocumentChangeType.modified){//Registro Atualizado
          String id = documentChange.document.documentID;
          dadosListen[id] = documentChange.document.data;
          iconImage = (dadosListen[id]['tipo'] == 'taxi')?'car-11':'car-15';//taxi ou bus
          await controller.updateSymbol(
            dadosSymbol[id],
            SymbolOptions(
              geometry: LatLng(
                dadosListen[id]['geoPoint'].latitude,
                dadosListen[id]['geoPoint'].longitude,
              ),
              iconImage: iconImage,
              iconSize: 1.3,
              iconAnchor: 'bottom',
              textField: dadosListen[id]['nome'],
              textAnchor: 'top',
            ),
          );

          if(_infoTransporteON){//Atualiza as informações quando aberto a aba de informações do transporte
            dadosSymbol.forEach((id, symbol) {
             if(symbol.id == _selectedSymbol.id){
               setState(() {
                 _auxT.text = dadosListen[id]['nome'];
                 _auxTipo.text = (marcadorOnibus[id]['tipo'] == 'bus')?'Ônibus':'Taxi-Lotação';
                 _auxRota.text = dadosListen[id]['rota'];
                 changeBus = true;
               });
               print("Informações atualizadas!");
             }
            });
          }
          print("Dado atualizado na lista! ${dadosListen[id]}");
        }else if(documentChange.type == DocumentChangeType.removed){//Registro Removido
          String id = documentChange.document.documentID;
          await controller.removeSymbol(dadosSymbol[id]);
          dadosListen.remove(id);
          dadosSymbol.remove(id);
          print("Dado removido da lista! ${documentChange.document.data}");
        }
      });
    });
    print("_addMarcadorPontoListen() - Fim");
  }

//  void _addTransporteListen(MapboxMapController controller) async{
//    print("_firebaseListen - Inicio");
//    FirebaseAuth user = FirebaseAuth.instance;
//    FirebaseUser usuarioLogado = await user.currentUser();
//    String userID = usuarioLogado.uid;
//    Firestore banco = Firestore.instance;
//    banco.collection('transporte').snapshots().listen(
//        (snapshot){
//          snapshot.documentChanges.forEach(
//              (documentChange) async{//As mudanças são em relação a variavel, não ao banco, ex: no inicio ele considera os dados que estão no banco como se fosse dados novos adicionados, pois são adicionado na varivel snapshot
//                print("documentChange");
//                if (documentChange.type == DocumentChangeType.added){
//                  String id = documentChange.document.documentID;
//                  if(id != userID){
//                    Map<String, dynamic> dados = documentChange.document.data;
//                    print(dados);
//                    Transporte transporte = new Transporte(id, dados['nome'], dados['tipo'], dados['rota'], dados['lat'].toDouble(), dados['lng'].toDouble(), dados['status']);
//                    Symbol symbol = await controller.addSymbol(
//                      SymbolOptions(
//                        geometry: LatLng(
//                          transporte.lat,
//                          transporte.lng,
//                        ),
//                      ),
//                    );
//                    listaTransporte.putIfAbsent(symbol, () => transporte);
//                    print("document: ${documentChange.document.data} added");
//                  }else{
//                    print("Usuário criou um transporte!");
//                  }
//                } else if (documentChange.type == DocumentChangeType.modified) {
//                  String id = documentChange.document.documentID;
//                  if(id != userID){
//                    Map<String, dynamic> dados = documentChange.document.data;
//                    Transporte transporteAux = new Transporte(id, dados['nome'], dados['tipo'], dados['rota'], dados['lat'].toDouble(), dados['lng'].toDouble(), dados['status']);
//                    print('status true');
//                    listaTransporte.forEach((id, transporte){
//                      if(transporte.id == transporteAux.id){
//                        print('id igual');
//                        String iconText;
//                        if(transporteAux.status){
//                          if(transporteAux.tipo == 'bus'){
//                            iconImage = 'car-15';
//                            iconColor = '#000000';
//                            iconText = transporteAux.nome;
//                          }else{
//                            iconImage = 'car-11';
//                            iconColor = '#054f77';
//                            iconText = transporteAux.nome;
//                          }
//                        }else{
//                          if(transporteAux.tipo == 'bus'){
//                            iconImage = 'none';
//                            iconColor = '#000000';
//                            iconText = '';
//                          }else{
//                            iconImage = 'none';
//                            iconColor = '#054f77';
//                            iconText = '';
//                          }
//                        }
//                        controller.updateSymbol(id, SymbolOptions(
//                            geometry: LatLng(
//                              transporteAux.lat,
//                              transporteAux.lng,
//                            ),
//                            iconImage: iconImage,
//                            iconColor: iconColor,
//                            iconSize: 1.3,
//                            iconAnchor: 'bottom',
//                            textField: iconText,
//                            textAnchor: 'top'
//                        ),);
//                        listaTransporte[id] = transporteAux;
//                      }
//                    });
//                    print("document: ${documentChange.document.data} modified");
////                    listaTransporte.forEach((key, value) {
////                      print("id:"+key.id+" valor:"+value.toMap().toString());
////                    });
//                    if(_infoTransporteON){
//                      listaTransporte.forEach((id, transporte) {
//                        if(id.id == _selectedSymbol.id){
//                          setState(() {
//                            _auxT.text = transporte.nome;
//                            _auxTipo = (transporte.tipo == 'bus')? false : true;
//                            _auxRota.text = transporte.rota;
//                          });
//                        }
//                      });
//                    }
//                  }else{
//                    print("Usuário alterou um transporte!");
//                  }
//                } else if (documentChange.type == DocumentChangeType.removed){
//                  String id = documentChange.document.documentID;
//                  Map<String, dynamic> dados = documentChange.document.data;
//                  Transporte transporteAux = new Transporte(id, dados['nome'], dados['tipo'], dados['rota'], dados['lat'].toDouble(), dados['lng'].toDouble(), dados['status']);
//                  print(transporteAux);
//                  listaTransporte.forEach((id, transporte){
//                    print('forEach');
//                    if(transporte.id == transporteAux.id){
//                      print('id igual');
//                      controller.removeSymbol(id);
//                      listaTransporte.remove(id);
//                    }
//                  });
//                  print("document: ${documentChange.document.data} removed");
//                }
//              }
//          );
//        }
//    );
//    print("_firebaseListen - Fim");
//  }

  void _recuperaUltimaLocalizacaoConhecida() async {
    print("_recuperaUltimaLocalizacaoConhecida() - Inicio");
    Position position = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      if(position != null){
        _meuGeoPoint = new GeoPoint(position.latitude, position.longitude);
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
        _meuSpeed = position.speed;
        _meuGeoPoint = new GeoPoint(position.latitude, position.longitude);
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
    GeoPoint minhaPosicao = new GeoPoint(_meuGeoPoint.latitude, _meuGeoPoint.longitude);
    GeoPoint pontoProximo = _encontrarParadaProxima();
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

  GeoPoint _encontrarParadaProxima(){
    print("_encontrarParadaProxima() - Inicio");
    _recuperaUltimaLocalizacaoConhecida();
    GeoPoint minhaPosicao = new GeoPoint(_meuGeoPoint.latitude, _meuGeoPoint.longitude);
    double distancia = 999999999999;
    String pontoProximo;
    marcadorParada.forEach((id, parada) {
      if(distancia > _calculaDistancia(minhaPosicao, parada['geoPoint'])){
        distancia = _calculaDistancia(minhaPosicao, parada['geoPoint']);
        pontoProximo = id;
      }
    });
    print("_encontrarParadaProxima() - Fim");
    return marcadorParada[pontoProximo]['geoPoint'];
  }

  void _gerarRota(Location minhaPosicao,Location destino) async {
    print("_gerarRota - Inicio");
    if(rotaGerada != null) _apagaRota();//Deletar desenho da rota se existir
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
    List<GeoPoint> pontosRota = new List();
    for(int i = 0; i < rotaJSON.length; i++) {
      rotaAUX.add(rotaJSON[i]['intersections']);
    }
    for(int i = 0; i < rotaAUX.length; i++) {
      for(int j = 0; j < rotaAUX[i].length; j++){
        GeoPoint aux = new GeoPoint(rotaAUX[i][j]['location'][1], rotaAUX[i][j]['location'][0]);
        pontosRota.add(aux);
      }
    }
    rotaGerada = pontosRota;
    calculaTime(rotaGerada);
    _desenhaRota(rotaGerada);
    print("_gerarRota - Fim");
  }

  void calculaTime(List<GeoPoint> pontosRota){
    print("calculaTime - Inicio");
    double distanciaTotal = 0;

    for(int i = 0; i < pontosRota.length; i++){
      if(i == 0) continue;
      distanciaTotal += _calculaDistancia(pontosRota[(i-1)], pontosRota[i]);
    }

    print("Distancia total é: " + distanciaTotal.toString());
    double speedKH = _meuSpeed;
    if(speedKH < 1.8){//-----------------------------------------Atenção
      setState(() {
        _timeKey = true;
        _myPoint = "Distância total é ${distanciaTotal.floor()*1000} metros";
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

  double _calculaDistancia(GeoPoint origin, GeoPoint destiny){
    print("_calculaDistancia - Inicio");
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((destiny.latitude - origin.latitude) * p)/2 +
        c(origin.latitude * p) * c(destiny.latitude * p) *
            (1 - c((destiny.longitude - origin.longitude) * p))/2;
    print("_calculaDistancia - Fim");
    return 12742 * asin(sqrt(a));
  }

  void _desenhaRota(List<GeoPoint> rotaGerada){
    print("_desenhaRota - Inicio");
    List<LatLng> rotaGeradaConvertida = new List();
    for(int i = 0; i < rotaGerada.length; i++){
      LatLng auxPoint = new LatLng(rotaGerada[i].latitude, rotaGerada[i].longitude);
      rotaGeradaConvertida.add(auxPoint);
    }
    mapController.addLine(
      LineOptions(
        geometry: rotaGeradaConvertida,
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

  void _apagaRota(){
    print("_apagaRota - Inicio");
    mapController.clearLines();
    print("_apagaRota - Fim");
  }

  Future<void> _criarTransporte() async {
    print("_criarTransporte - Inicio");
    _filaEspera = await _verificaBusProximo();
    _meuTransporte = new Transporte('', _nomeBus.text, (_tipo)?'taxi':'bus', _rotaBus.text, _meuGeoPoint);
    if(!_filaEspera){
      print("Ônibus ON!!!");
      _meuTransporte.create();
      _busON = true;
    }else{
      print("Ônibus OFF!!!");
      _busON = false;
    }
    _transporteON = true;
    print("_criarTransporte - Fim");
  }

  Future<void> _atualizarTransporte() async {
    print("_atualizarTransporte - Inicio");
    if(_busON){
      _meuTransporte = Transporte('', _nomeBus.text, (_tipo)?'taxi':'bus', _rotaBus.text, _meuGeoPoint);
      _meuTransporte.update();
    }else{
      _filaEspera = await _verificaBusProximo();
      if(!_filaEspera){
        _meuTransporte = Transporte('', _nomeBus.text, (_tipo)?'taxi':'bus', _rotaBus.text, _meuGeoPoint);
        _meuTransporte.create();
        _busON = true;
      }
    }
    print("_atualizarTransporte - Fim");
  }

  Future<void> _deletarTransporte() async {
    print("_deletarTransporte - Inicio");
    _transporteON = false;
    print(_meuTransporte.id);
    await _meuTransporte.delete();
    _busON = false;
    print("_deletarTransporte - Fim");
  }

  Future<bool> _verificaBusProximo() async {//Verifica se existe bus perto, caso n tenha, dá permissão para ativar o bus do user(isso é transparente para o user)
    print("_verificaBusProximo - Inicio");
    GeoPoint posicao = _meuGeoPoint;
    Map<String, dynamic> _busPerto = _buscarMarcadorProximo(marcadorOnibus, 50.00);//Pega todos os bus dentro do raio
    double distancia = 50.00;
    String idBusProximo;
    _busPerto.forEach((id, transporte) {//Encontra o bus mais proxima para ser o busMain
      if(distancia >= _calculaDistancia(posicao, transporte['geoPoint'])){
        distancia = _calculaDistancia(posicao, transporte['geoPoint']);
        idBusProximo = id;
      }
    });

    print(idBusProximo);

    print("_verificaBusProximo - Fim");

    if(idBusProximo != null && idBusProximo != ''){
      print("Lendo ônibus proximo...");
      _busMainFila = new Transporte();
      await _busMainFila.read(idBusProximo);

      if(_busMainFila.id != null && _busMainFila.id != ''){
        print("Entrando na fila de espera!");
        print(_busMainFila.toMap());
        return true;//Se existe um ônibus, então o user não vai ativar o seu bus e entrará na fila de espera
      }else{
        return false;
      }
    }else{
      return false;
    }
  }

  Map<String, dynamic> _buscarMarcadorProximo(Map<String, dynamic> marcadorList, double raioDistancia){//Verifica os bus dentro do raio em metros(ao redor do user)
    print("_buscarBusProximo - Inicio");
    Map<String, dynamic> _marcadorDentroRaio = new Map();
    marcadorList.forEach((id, transporte) {
      GeoPoint auxTransportePoint = transporte['geoPoint'];
      GeoPoint auxMyPoint = _meuGeoPoint;
      double _distancia = _calculaDistancia(auxMyPoint, auxTransportePoint);
      if(_distancia <= raioDistancia){
        print("Encontrou ônibus próximo!");
        _marcadorDentroRaio.putIfAbsent(id, () => transporte);
      }else{
        print("Ônibus está distante!");
      }
    });
    print("_buscarBusProximo - Fim");
    return _marcadorDentroRaio;
  }

  Future<void> _verificaPontoBusProximo() async {//Verifica se existe ponto de bus perto, caso n tenha, dá permissão para ativar o bus do user(isso é transparente para o user)
    print("_verificaPontoBusProximo - Inicio");
    GeoPoint posicao = _meuGeoPoint;
    Map<String, dynamic> _pontoBusPerto = _buscarMarcadorProximo(marcadorParada, 50.00);//Pega todos pontos de bus dentro do raio
    double distancia = 50.00;
    String idPontoBusProximo;
    _pontoBusPerto.forEach((id, transporte) {//Encontra o ponto de bus mais proxima para ser o pointBusMain
      if(distancia >= _calculaDistancia(posicao, transporte['geoPoint'])){
        distancia = _calculaDistancia(posicao, transporte['geoPoint']);
        idPontoBusProximo = id;
      }
    });

    print(idPontoBusProximo);

    if(idPontoBusProximo != null){
      print("Lendo ponto de ônibus proximo...");
      await _pontoBusMain.read(idPontoBusProximo);
      print("Ponto de ônibus: ${_pontoBusMain.toMap()}");
    }else{
      _pontoBusMain = new PontoBus();
    }

    if(_pontoBusMain.id != null && _pontoBusMain.id != ''){
      print(_pontoBusMain.toMap());
      setState(() {
        txtPontoBus = "Alterar Ponto de Ônibus";
        _nomePointBus.text = _pontoBusMain.nome;
        _descricaoPointBus.text = _pontoBusMain.descricao;
        pontoBusON = true;
      });
      print("_verificaPontoBusProximo - Fim");
    }else{
      setState(() {
        txtPontoBus = "Criar Ponto de Ônibus";
        _nomePointBus.text = '';
        _descricaoPointBus.text = '';
        pontoBusON = false;
      });
      print("_verificaPontoBusProximo - Fim");
    }
  }

  Future<void> _criarPontoBus() async {
    print("_criarPontoBus - Inicio");
    PontoBus pontoBus = new PontoBus('', _nomePointBus.text, _descricaoPointBus.text, _meuGeoPoint);
    await pontoBus.create();
    print("_criarPontoBus - Fim");
  }

  Future<void> _atualizarPontoBus(String id) async {
    print("_atualizarPontoBus - Inicio");
    PontoBus pontoBus = new PontoBus(id, _nomePointBus.text, _descricaoPointBus.text, _meuGeoPoint);
    await pontoBus.update();
    print("_atualizarPontoBus - Fim");
  }

  Future<void> _deletarPontoBus(String id) async {
    print("_deletarPontoBus - Inicio");
    PontoBus pontoBus = new PontoBus(id);
    await pontoBus.delete();
    print("_deletarPontoBus - Fim");
  }

  Future<dynamic> criarTransporteComPonto([String destino, bool onread]){
    onread ??= false;
    _rotaBus.text = destino;
    return showDialog(
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
                            labelText: 'Qual rota está fazendo?',
                        ),
                        controller: _rotaBus,
                        readOnly: onread,
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
          Padding(//Botão de CRUD do ponto de parada
            padding: EdgeInsets.only(bottom: 10),
            child: Container(
              height: 60.0,
              width: 60.0,
              child: FittedBox(
                child: FloatingActionButton(
                  heroTag: 'btnGPS',
                  child: Icon(_iconGPS),
                  backgroundColor: _colorGPS,
                  onPressed: (){
                    setState(() {
                      _iconGPS = (_myLocationEnabled)?Icons.gps_off:Icons.gps_fixed;
                      _colorGPS = (_myLocationEnabled)?Colors.black54:Colors.blue;
                      _myLocationEnabled = !(_myLocationEnabled);
                      _scrollGesturesEnabled = !(_scrollGesturesEnabled);
                      if(_myLocationEnabled){
                        mapController.moveCamera(
                          CameraUpdate.newCameraPosition(_myLocal),
                        );
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          Padding(//Botão de CRUD do ponto de parada
            padding: EdgeInsets.only(bottom: 10),
            child: Container(
              height: 60.0,
              width: 60.0,
              child: FittedBox(
                child: FloatingActionButton(
                  heroTag: 'btnPoint',
                  child: Icon(Icons.add_location),
                  backgroundColor: Colors.amberAccent,
                  onPressed: () async {
                    await _verificaPontoBusProximo();
                    showDialog(
                        context: context,
                        builder: (context){
                          return StatefulBuilder(
                            builder: (context, setState){
                              return AlertDialog(
                                title: Text(
                                    txtPontoBus
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      if(pontoBusON)Text(
                                          "OBS: Não é possivel criar um ponto muito proximo de outro!",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red
                                          ),
                                      ),
                                      TextField(
                                        decoration: InputDecoration(
                                            labelText: 'Nome do local'
                                        ),
                                        controller: _nomePointBus,
                                      ),
                                      TextField(
                                        decoration: InputDecoration(
                                            labelText: 'Descrição do local ou ponto de referência'
                                        ),
                                        controller: _descricaoPointBus,
                                      ),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                    child: (pontoBusON)?Text('Excluir'):Text('Cancelar'),
                                    onPressed: () {
                                      if(pontoBusON)_deletarPontoBus(_pontoBusMain.id);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  FlatButton(
                                    child: (pontoBusON)?Text('Salvar'):Text('Criar'),
                                    onPressed: (){
                                      //Salvar no banco de dados
                                      (pontoBusON)?_atualizarPontoBus(_pontoBusMain.id):_criarPontoBus();
                                      Navigator.pop(context);
                                      super.setState(() {

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
          if(_gps) Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Container(
              height: 50.0,
              width: 50.0,
              child: FittedBox(
                child: FloatingActionButton(
                  heroTag: 'btnCancelar',
                  child: Icon(Icons.cancel),
                  backgroundColor: Colors.red,
                  onPressed: (){
                    if(_busON){
                      _deletarTransporte();
                    }
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
              height: 60.0,
              width: 60.0,
              child: FittedBox(
                child: FloatingActionButton(
                  heroTag: 'btnBus',
                  child: Icon(Icons.directions_bus),
                  backgroundColor: _btnBus,
                  onPressed: (){
                    criarTransporteComPonto();
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
