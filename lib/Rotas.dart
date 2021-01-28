import 'package:MyBus/telas/Cadastro.dart';
import 'package:MyBus/telas/FeedbackNota.dart';
import 'package:MyBus/telas/Home.dart';
import 'package:MyBus/telas/Info.dart';
import 'package:MyBus/telas/Mapa.dart';
import 'package:flutter/material.dart';

class Rotas {

  static Route<dynamic> gerarRotas(RouteSettings settings){
    switch( settings.name ){
      case "/" :
        return MaterialPageRoute(
            builder: (_) => Home()
        );
      case "/cadastro" :
        return MaterialPageRoute(
            builder: (_) => Cadastro()
        );
      case "/mapa" :
        return MaterialPageRoute(
            builder: (_) => Mapa()
        );
      case "/info" :
        return MaterialPageRoute(
            builder: (_) => Info()
        );
      case "/feedback" :
        return MaterialPageRoute(
            builder: (_) => FeedbackNota()
        );
      default:
        return _erroRota();
    }

  }

  static Route<dynamic> _erroRota(){

    return MaterialPageRoute(
        builder: (_){
          return Scaffold(
            appBar: AppBar(title: Text("Tela não encontrada!"),),
            body: Center(
              child: Text("Tela não encontrada!"),
            ),
          );
        }
    );

  }

}