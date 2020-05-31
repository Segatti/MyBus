
class Usuario {

  String _idUsuario;
  String _nome;
  String _email;
  String _senha;
  String _tipoUsuario;
  String _app;
  String _especial;
  String _qtdOnibus;
  String _timeOnibus;
  String _notaOnibus;

  Usuario();

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

  String get tipoUsuario => _tipoUsuario;

  set tipoUsuario(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _tipoUsuario = value;
  }

  String get senha => _senha;

  set senha(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _senha = value;
  }

  String get email => _email;

  set email(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _email = value;
  }

  String get nome => _nome;

  set nome(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _nome = value;
  }

  String get idUsuario => _idUsuario;

  set idUsuario(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _idUsuario = value;
  }

  String get notaOnibus => _notaOnibus;

  set notaOnibus(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _notaOnibus = value;
  }

  String get timeOnibus => _timeOnibus;

  set timeOnibus(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _timeOnibus = value;
  }

  String get qtdOnibus => _qtdOnibus;

  set qtdOnibus(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _qtdOnibus = value;
  }

  String get especial => _especial;

  set especial(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _especial = value;
  }

  String get app => _app;

  set app(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _app = value;
  }


}