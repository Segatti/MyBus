import 'package:flutter/material.dart';
import 'package:mybus/telas/Cadastro.dart';
import 'package:mybus/telas/Home.dart';
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
      default:
        _erroRota();
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