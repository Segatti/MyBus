import 'package:cloud_firestore/cloud_firestore.dart';
import 'Firebase.dart';

class Transporte{
  //Atributos
  String id;
  String nome;
  String tipo;
  String rota;
  GeoPoint geoPoint;
  Timestamp timestamp;

  //Funções Primitivas
  Transporte([this.id, this.nome, this.tipo, this.rota, this.geoPoint]);
  
  //Funções Específicas
  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      "nome" : this.nome,
      "tipo" : this.tipo,
      "rota" : this.rota,
      "geoPoint" : this.geoPoint,
      "timeStamp" : DateTime.now(),
    };
    return map;
  }

  Map<String, dynamic> toFila(String idBusMain){
    Map<String, dynamic> map = {
      "busMain" : idBusMain,
      "timeStamp" : DateTime.now(),
    };
    return map;
  }

  Future entrarFila(String idBusMain) async{
    Firebase firebase = new Firebase();
    dynamic id = await firebase.create('fila_espera', this.toFila(idBusMain), true);
    this.id = id;
    print("Entrou na fila de espera!");
  }

  Future lerFila(String idBusMain) async{
    Firestore firestore = new Firestore();
    Map<String, dynamic> dados = new Map();
    QuerySnapshot querySnapshot = await firestore.collection('fila_espera').where(['idBusMain', '=', idBusMain]).orderBy('timeStamp').getDocuments();
    for(DocumentSnapshot item in querySnapshot.documents){
      dados.putIfAbsent(item.documentID, () => item.data);
    }
    print("Fila lida com sucesso! $dados");
    return dados;
  }
  
  //Funções Básicas
  Future create() async{
    Firebase firebase = new Firebase();
    this.id = await firebase.create('transporte', this.toMap(), true);
    print("Transporte criado com sucesso! $id");
  }

  Future read([String id, Map<String, dynamic> dados]) async{
    Firebase firebase = new Firebase();
    if(dados == null && id == null){
      Map<String, dynamic> dados = await firebase.read('transporte');
      print("Todos os transportes foram lidos! $dados");
      return dados;
    }else if(id == null){
      await firebase.read('transporte', '', true, dados);
      print("Ativado modo 'listen' para transporte! $dados");
    }else if(id != ''){
      Map<String, dynamic> dados = await firebase.read('transporte', id);
      print("O transporte foi lido! $dados");
      this.id = id;
      this.nome = dados['nome'];
      this.tipo = dados['tipo'];
      this.rota = dados['rota'];
      this.geoPoint = dados['geoPoint'];
      this.timestamp = dados['timeStamp'];
    }else{
      print("Houve um problema com relação aos parâmetros para ler transportes!");
    }
  }

  Future update() async{
    Firebase firebase = new Firebase();
    bool status = await firebase.update('transporte', this.id, this.toMap());
    print("O transporte foi atualizado com sucesso! $status");
  }

  Future delete() async{
    Firebase firebase = new Firebase();
    bool status = await firebase.delete('transporte', this.id);
    print("O transporte foi deletado com sucesso! $status");
  }
  
}