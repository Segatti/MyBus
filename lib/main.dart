import 'package:MyBus/telas/Home.dart';
import 'package:MyBus/telas/Mapa.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'Rotas.dart';

final ThemeData temaPadrao = ThemeData(
  primaryColor: Color(0xff37474f),
  accentColor: Color(0xff546e7a)
);

void main(){
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) async {
    _recuperaUltimaLocalizacaoConhecida();
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    runApp(MaterialApp(
      title: "MyBus",
      home: (usuarioLogado != null)? Mapa() : Home(),
      theme: temaPadrao,
      initialRoute: "/",
      onGenerateRoute: Rotas.gerarRotas,
      debugShowCheckedModeBanner: false,
    ));
  });
}

void _recuperaUltimaLocalizacaoConhecida() async {
  print("_recuperaUltimaLocalizacaoConhecida() - Inicio");
  await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
  print("_recuperaUltimaLocalizacaoConhecida() - Fim");
}