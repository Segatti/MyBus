import 'package:flutter/material.dart';
import 'package:mybus/telas/Cadastro.dart';
import 'package:mybus/telas/FeedbackNota.dart';
import 'package:mybus/telas/Home.dart';
import 'package:mybus/telas/Horarios.dart';
import 'package:mybus/telas/Info.dart';
import 'package:mybus/telas/Mapa.dart';

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
      case "/horarios" :
        return MaterialPageRoute(
            builder: (_) => Horarios()
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