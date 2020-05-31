import 'package:flutter/material.dart';
import 'package:mybus/model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {

  TextEditingController _controllerNome = TextEditingController(text: "MyBus");
  TextEditingController _controllerEmail = TextEditingController(text: "mybus@gmail.com");
  TextEditingController _controllerSenha = TextEditingController(text: "1234567");
  bool _tipoUsuario = false;
  bool _app = false;
  bool _especial = false;
  double _qtdOnibus = 0.0;
  double _timeOnibus = 0.0;
  double _notaOnibus = 0.0;
  String _mensagemErro = "";

  _validarCampos(){

    //Recuperar dados dos campos
    String nome = _controllerNome.text;
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;
    String qtdBus = _qtdOnibus.floor().toString();
    String timeBus = _timeOnibus.floor().toString();
    String notaBus = _notaOnibus.floor().toString();

    //validar campos
    if( nome.trim().isNotEmpty ){

      if( email.trim().isNotEmpty && email.contains("@") ){

        if( senha.trim().isNotEmpty && senha.length > 6 ){

          if( _qtdOnibus != 0 || _timeOnibus != 0 ){

            Usuario usuario = Usuario();
            usuario.nome = nome;
            usuario.email = email;
            usuario.senha = senha;
            usuario.tipoUsuario = usuario.verificaTipoUsuario(_tipoUsuario);
            usuario.app = usuario.verificaOpcao(_app);
            usuario.especial = usuario.verificaOpcao(_especial);
            usuario.qtdOnibus = qtdBus;
            usuario.timeOnibus = timeBus;
            usuario.notaOnibus = notaBus;

            _cadastrarUsuario( usuario );

          }else{
            setState(() {
              _mensagemErro = "Preencha o formulário corretamente!";
            });
          }

        }else{
          setState(() {
            _mensagemErro = "Preencha a senha! digite mais de 6 caracteres";
          });
        }

      }else{
        setState(() {
          _mensagemErro = "Preencha o E-mail válido";
        });
      }

    }else{
      setState(() {
        _mensagemErro = "Preencha o Nome";
      });
    }

  }

  _cadastrarUsuario( Usuario usuario ){

    FirebaseAuth auth = FirebaseAuth.instance;
    Firestore db = Firestore.instance;

    auth.createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha
    ).then((firebaseUser){

      db.collection("usuarios")
          .document( firebaseUser.user.uid )
          .setData( usuario.toMap() );

      //redireciona para o painel, de acordo com o tipoUsuario
      switch( usuario.tipoUsuario ){
        case "usuario" :
          Navigator.pushNamedAndRemoveUntil(
              context,
              "/mapa",
              (_) => false
          );
          break;
        case "admin" :
          Navigator.pushNamedAndRemoveUntil(
              context,
              "/mapa-admin",
                  (_) => false
          );
          break;
      }

    }).catchError((error){
      _mensagemErro = "Erro ao cadastrar usuário, verifique os campos e tente novamente!";
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastro"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _controllerNome,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Nome completo",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),
                TextField(
                  controller: _controllerEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "e-mail",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),
                TextField(
                  controller: _controllerSenha,
                  obscureText: true,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "senha",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      Text("Usuário"),
                      Switch(
                          value: _tipoUsuario,
                          onChanged: (bool valor){
                            setState(() {
                              _tipoUsuario = valor;
                            });
                          }
                      ),
                      Text("Administrador"),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    "------------------ FORMULÁRIO ------------------",
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(0),
                  child: Text(
                    "Você acredita que este tipo de aplicativo é importante para a cidade?",
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      Text("Não"),
                      Switch(
                          value: _app,
                          onChanged: (bool valor){
                            setState(() {
                              _app = valor;
                            });
                          }
                      ),
                      Text("Sim"),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(0),
                  child: Text(
                    "Você é portador de necessidades especiais?",
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      Text("Não"),
                      Switch(
                          value: _especial,
                          onChanged: (bool valor){
                            setState(() {
                              _especial = valor;
                            });
                          }
                      ),
                      Text("Sim"),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(0),
                  child: Text(
                    "Em média, quantos ônibus você pega diariamente?",
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Slider(
                    value: _qtdOnibus,
                    min: 0,
                    max: 10,
                    label: _qtdOnibus.floor().toString(),
                    divisions: 10,
                    onChanged: (double valor){
                      setState(() {
                        _qtdOnibus = valor;
                      });
                    },
                  )
                ),
                Padding(
                  padding: EdgeInsets.all(0),
                  child: Text(
                    "Em média, quantos tempo você espera por um ônibus? (0-60 minutos)",
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Slider(
                      value: _timeOnibus,
                      min: 0,
                      max: 60,
                      label: _timeOnibus.floor().toString(),
                      divisions: 60,
                      onChanged: (double valor){
                        setState(() {
                          _timeOnibus = valor;
                        });
                      },
                    )
                ),
                Padding(
                  padding: EdgeInsets.all(0),
                  child: Text(
                    "Que nota você daria ao transporte público da cidade?",
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Slider(
                      value: _notaOnibus,
                      min: 0,
                      max: 10,
                      label: _notaOnibus.floor().toString(),
                      divisions: 10,
                      onChanged: (double valor){
                        setState(() {
                          _notaOnibus = valor;
                        });
                      },
                    )
                ),
                Padding(
                  padding: EdgeInsets.all(0),
                  child: Text(
                    "OBS: Estes dados do formulário serão utilizados no projeto de extensão MyBus da UNIFESSPA.",
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                      child: Text(
                        "Cadastrar",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      color: Color(0xff1ebbd8),
                      padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      onPressed: (){
                        _validarCampos();
                      }
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _mensagemErro,
                      style: TextStyle(color: Colors.red, fontSize: 20),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
