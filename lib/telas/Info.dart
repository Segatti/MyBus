import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:isolate';

class Info extends StatefulWidget {
  Info({Key key}) : super(key: key);
  @override
  _InfoState createState() => _InfoState();
}

class _InfoState extends State<Info> {
  List widgets = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  showLoadingDialog() {
    if (widgets.length == 0) {
      return true;
    }
    return false;
  }

  getBody() {
    if (showLoadingDialog()) {
      return getProgressDialog();
    } else {
      return getListView();
    }
  }

  getProgressDialog() {
    return Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Thread App"),
        ),
        body: getBody());
  }

  ListView getListView() => ListView.builder(
      itemCount: widgets.length,
      itemBuilder: (BuildContext context, int position) {
        return getRow(position);
      });

  Widget getRow(int i) {
    return Padding(padding: EdgeInsets.all(10.0), child: Text("Row ${widgets[i]["title"]}"));
  }

  loadData() async {
    // Abre a porta para receber a porta de comunicação dentro do Isolate
    ReceivePort receiveIsolatePort = ReceivePort();
    // Cria o Isolate com o metodo e a porta criada anteriormente
    await Isolate.spawn(dataLoader, receiveIsolatePort.sendPort);

    // Guarda a porta enviada pelo Isolate
    SendPort sendToIsolatePort = await receiveIsolatePort.first;

    // Envia a requisição com o link para o Isolate baixar o json
    List msg = await sendReceive(sendToIsolatePort, "https://jsonplaceholder.typicode.com/posts");

    // Exibi os dados baixados
    setState(() {
      widgets = msg;
    });
  }

  // O metodo do Isolate
  static dataLoader(SendPort sendPort) async {
    // Abre a porta para receber as requisições
    ReceivePort port = ReceivePort();

    // Envia para a main thread a porta
    sendPort.send(port.sendPort);

    // Espera receber a requisição
    await for (var msg in port) {
      // Link do json
      String data = msg[0];
      // Porta para retornar
      SendPort replyTo = msg[1];

      http.Response response = await http.get(data);
      // Envia a resposta do http
      replyTo.send(json.decode(response.body));
    }
  }

  Future sendReceive(SendPort port, link) {
    // Abre uma porta para receber a resposta da requisição
    ReceivePort response = ReceivePort();
    // Envia para o Isolate o link e a porta de resposta
    port.send([link, response.sendPort]);
    return response.first;
  }
}
