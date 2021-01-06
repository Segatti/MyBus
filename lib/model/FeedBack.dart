import 'Firebase.dart';

class FeedBack{
  //Atributos
  String id;
  double nota;
  String msg;

  //Funções Primitivas
  FeedBack([this.id, this.nota, this.msg]);

  //Funções Específicas
  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      "nota" : this.nota,
      "msg" : this.msg,
    };
    return map;
  }

  //Funções Básicas
  Future create() async{
    Firebase firebase = new Firebase();
    dynamic id = await firebase.create('feedback', this.toMap(), true);
    this.id = id;
    print("Feedback criado com sucesso! $id");
  }

  Future read([String id]) async{
    if(id != '' && id != null){
      Firebase firebase = new Firebase();
      Map<String, dynamic> dados = await firebase.read('feedback', id);
      this.id = id;
      this.nota = dados['nota'];
      this.msg = dados['msg'];
      print("O feedback foi lido! $dados");
    }else{
      Firebase firebase = new Firebase();
      Map<String, dynamic> dados = await firebase.read('feedback');
      print("Todos os feedbacks foram lidos! $dados");
      return dados;
    }
  }

  Future update() async{
    Firebase firebase = new Firebase();
    bool status = await firebase.update('feedback', this.id, this.toMap());
    print("O feedback foi atualizado com sucesso! $status");
  }

  Future delete() async{
    Firebase firebase = new Firebase();
    bool status = await firebase.delete('feedback', this.id);
    print("O feedback foi deletado com sucesso! $status");
  }
}