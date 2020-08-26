import 'package:cloud_firestore/cloud_firestore.dart';
import 'Firebase.dart';

class PontoBus {
  //Atributos
  String id;
  String nome;
  String descricao;
  GeoPoint geoPoint;
  Timestamp timestamp;

  //Funções Primitivos
  PontoBus([this.id, this.nome, this.descricao, this.geoPoint]);

  //Funções Específicos
  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      "nome" : this.nome,
      "descricao" : this.descricao,
      "geoPoint" : this.geoPoint,
      "timeStamp" : DateTime.now(),
    };
    return map;
  }

  //Funções Básicas
  Future create() async{
    Firebase firebase = new Firebase();
    this.id = await firebase.create('ponto_onibus', this.toMap());
    print("Ponto criado com sucesso! $id");
  }

  Future read([String id, Map<String, dynamic> dados]) async{
    Firebase firebase = new Firebase();
    if(dados == null && id == null){
      Map<String, dynamic> dados = await firebase.read('ponto_onibus');
      print("Todos os pontos foram lidos! $dados");
      return dados;
    }else if(id == null){
      await firebase.read('ponto_onibus', '', true, dados);
      print("Ativado modo 'listen' para ponto de ônibus! $dados");
    }else if(id != ''){
      Map<String, dynamic> dados = await firebase.read('ponto_onibus', id);
      print("O ponto foi lido! $dados");
      this.id = id;
      this.nome = dados[id]['nome'];
      this.geoPoint = dados[id]['geoPoint'];
      this.timestamp = dados[id]['timeStamp'];
    }else{
      print("Houve um problema com relação aos parâmetros para ler pontos de ônibus!");
    }
  }

  Future update() async{
    Firebase firebase = new Firebase();
    bool status = await firebase.update('ponto_onibus', this.id, this.toMap());
    print("O ponto foi atualizado com sucesso! $status");
  }

  Future delete() async{
    Firebase firebase = new Firebase();
    bool status = await firebase.delete('ponto_onibus', this.id);
    print("O ponto foi deletado com sucesso! $status");
  }
}
