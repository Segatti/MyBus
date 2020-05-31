import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedBack{
  //Atributos
  String _id;
  double _nota;
  String _msg;

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
    Firestore banco = Firestore.instance;
    FirebaseAuth user = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await user.currentUser();
    banco.collection('feedback').document(usuarioLogado.uid).setData(this.toMap());
  }

  Future read() async{
    Firestore banco = Firestore.instance;
    QuerySnapshot querySnapshot = await banco.collection('feedback').getDocuments();
    List<FeedBack> dados = new List();
    for(DocumentSnapshot item in querySnapshot.documents){
      dados.add(new FeedBack(item.documentID, item.data['nota'], item.data['tipo']));
    }
    return dados;
  }

  Future update(Map<String, dynamic> map) async{
    Firestore banco = Firestore.instance;
    FirebaseAuth user = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await user.currentUser();
    banco.collection('feedback').document(usuarioLogado.uid).updateData(map);
  }

  Future delete() async{
    Firestore banco = Firestore.instance;
    FirebaseAuth user = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await user.currentUser();
    banco.collection('feedback').document(usuarioLogado.uid).delete();
  }

  //Funções Primitivas
  FeedBack(this._id, this._nota, this._msg);

  String get id => _id;

  set id(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _id = value;
  }

  String get msg => _msg;

  set msg(String value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _msg = value;
  }

  double get nota => _nota;

  set nota(double value) {
    if(value == null) {
      throw new ArgumentError();
    }
    _nota = value;
  }


}