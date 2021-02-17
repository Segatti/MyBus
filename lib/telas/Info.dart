import 'package:flutter/material.dart';

class Info extends StatelessWidget {

  _criarLinhaTable(String listaNomes) {
    return TableRow(
      children: listaNomes.split(';').map((name) {
        return Container(
          alignment: Alignment.center,
          child: Text(
            name,
            style: TextStyle(fontSize: 20.0),
          ),
          padding: EdgeInsets.all(8.0),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Informações sobre o projeto",
            style: TextStyle(
                fontSize: 18
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.black,
                    style: BorderStyle.solid,
                    width: 1.0,
                  ),
                  verticalInside: BorderSide(
                    color: Colors.black,
                    style: BorderStyle.solid,
                    width: 1.0,
                  ),
                ),
                children: [
                  _criarLinhaTable("Nome do projeto"),
                  _criarLinhaTable("MyBus"),
                  _criarLinhaTable(""),
                  _criarLinhaTable("Periodo de desenvolvimento"),
                  _criarLinhaTable("2020"),
                  _criarLinhaTable(""),
                  _criarLinhaTable("Participantes"),
                  _criarLinhaTable("Aluno: Vittor Feitosa (vittor_segatti@unifesspa.edu.br), Professores: Nadson (nadsonwelkson@unifesspa.edu.br) e Gleison (gleison@unifesspa.edu.br)"),
                  _criarLinhaTable(""),
                  _criarLinhaTable("Objetivo"),
                  _criarLinhaTable("Este é um projeto da UNIFESSPA que tem como objetivo ser uma alternativa para localização do transporte público de Marabá - PA, onde qualquer pessoa pode compartilhar sua localização quando estiver dentro de um ônibus, com os demais usuários."),
                  _criarLinhaTable(""),
                ],
              ),
            ],
          ),
        )
    );
  }
}
