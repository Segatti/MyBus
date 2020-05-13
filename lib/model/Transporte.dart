import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class Transporte{
  //Atributos
  String _id;
  String _nome;
  String _tipo;
  String _rota;
  double _lat;
  double _lng;
  bool _status;
  
  //Funções Específicas
  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      "nome" : this.nome,
      "tipo" : this.tipo,
      "rota" : this.rota,
      "lat" : this.lat,
      "lng" : this.lng,
      "status" : this.status 
    };
    return map;
  }
  
  //Funções Básicas
  Future create() async{
    Firestore banco = Firestore.instance;
    FirebaseAuth user = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await user.currentUser();
    banco.collection('transporte').document(usuarioLogado.uid).setData(this.toMap());
  }

  Future read() async{
    Firestore banco = Firestore.instance;
    QuerySnapshot querySnapshot = await banco.collection('transporte').where('status', isEqualTo: true).getDocuments();
    List<Transporte> dados = new List();
    for(DocumentSnapshot item in querySnapshot.documents){
      dados.add(new Transporte(item.documentID, item.data['nome'], item.data['tipo'], item.data['rota'], item.data['lat'].toDouble(), item.data['lng'].toDouble(), item.data['status']));
    }
    return dados;
  }

  Future update(Map<String, dynamic> map) async{
    Firestore banco = Firestore.instance;
    FirebaseAuth user = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await user.currentUser();
    banco.collection('transporte').document(usuarioLogado.uid).updateData(map);
  }

  Future delete() async{
    Firestore banco = Firestore.instance;
    FirebaseAuth user = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await user.currentUser();
    Map<String, dynamic> dado = {
      "status" : false
    };
    banco.collection('transporte').document(usuarioLogado.uid).updateData(dado);
  }

  //Funções Primitivas
  Transporte(this._id, this._nome, this._tipo, this._rota, this._lat, this._lng, this._status);

  String get id => _id;

  set id(String value) {
    _id = value;
  }

  String get nome => _nome;

  set nome(String value) {
    _nome = value;
  }

  String get tipo => _tipo;

  set tipo(String value) {
    _tipo = value;
  }

  String get rota => _rota;

  set rota(String value) {
    _rota = value;
  }

  double get lat => _lat;

  set lat(double value) {
    _lat = value;
  }

  bool get status => _status;

  set status(bool value) {
    _status = value;
  }

  double get lng => _lng;

  set lng(double value) {
    _lng = value;
  }


}