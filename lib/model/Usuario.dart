import 'Firebase.dart';

class Usuario {
  //Atributos
  String idUsuario;
  String nome;
  String email;
  String senha;
  String tipoUsuario;
  String app;
  String especial;
  String qtdOnibus;
  String timeOnibus;
  String notaOnibus;

  //Funções primitivas
  Usuario([this.idUsuario, this.nome, this.email, this.senha, this.tipoUsuario, this.app, this.especial, this.qtdOnibus, this.timeOnibus, this.notaOnibus]);

  //Funções Específicas
  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      "nome" : this.nome,
      "email" : this.email,
      "tipoUsuario" : this.tipoUsuario,
      "appUtil" : this.app,
      "especial" : this.especial,
      "qtdOnibus" : this.qtdOnibus,
      "timeOnibus" : this.timeOnibus,
      "notaOnibus" : this.notaOnibus,
    };
    return map;
  }

  String verificaTipoUsuario(bool tipoUsuario){
    return tipoUsuario ? "admin" : "usuario";
  }

  String verificaOpcao(bool opcao){
    return opcao ? "Sim" : "Não";
  }

  //Funções Básicas
  Future create() async{
    Firebase firebase = new Firebase();
    this.idUsuario = await firebase.create('usuarios', this.toMap(), true);
    print("Usuário criado com sucesso! $idUsuario");
  }

  Future read([String id, Map<String, dynamic> dados]) async{
    Firebase firebase = new Firebase();
    if(dados == null && id == null){
      Map<String, dynamic> dados = await firebase.read('usuarios');
      print("Todos os usuarios foram lidos! $dados");
      return dados;
    }else if(id == null){
      await firebase.read('usuarios', '', true, dados);
      print("Ativado modo 'listen' para usuarios! $dados");
    }else if(id != ''){
      Map<String, dynamic> dados = await firebase.read('usuarios', id);
      print("O usuario foi lido! $dados");
      this.idUsuario = id;
      this.nome = dados[id]['nome'];
      this.email = dados[id]['email'];
      this.tipoUsuario = dados[id]['tipoUsuario'];
      this.app = dados[id]['appUtil'];
      this.especial = dados[id]['especial'];
      this.qtdOnibus = dados[id]['qtdOnibus'];
      this.timeOnibus = dados[id]['timeOnibus'];
      this.notaOnibus = dados[id]['notaOnibus'];
    }else{
      print("Houve um problema com relação aos parâmetros para ler usuarios!");
    }
  }

  Future update() async{
    Firebase firebase = new Firebase();
    bool status = await firebase.update('usuarios', this.idUsuario, this.toMap());
    print("Usuário foi atualizado com sucesso! $status");
  }

  Future delete() async{
    Firebase firebase = new Firebase();
    bool status = await firebase.delete('usuarios', this.idUsuario);
    print("Usuário foi deletado com sucesso! $status");
  }
}