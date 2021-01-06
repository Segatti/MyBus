import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Firebase{
  //Atributos
  FirebaseAuth firebaseAuth;
  Firestore firestore;

  //Funções Primitivas
  Firebase(){
    this.firebaseAuth = FirebaseAuth.instance;
    this.firestore = Firestore.instance;
  }

  //Funções Específicas
  //Aqui entrará futuramente, funções do FireabaseAuth e etc.

  //Funções Básicas
  Future<String> create(String tabela, Map<String, dynamic> dado, [bool userId, String id]) async{
    String idValor = '';
    userId ??= false;//Se for null, recebe false!
    if(userId && id == null){
      FirebaseUser firebaseUser = await firebaseAuth.currentUser();
      await firestore.collection(tabela).document(firebaseUser.uid).setData(dado)
          .then((value){
        print("Dado registrado com sucesso e com UID!");
        idValor = firebaseUser.uid;
      })
          .catchError((onError){
        print("Falha ao tentar registrar dado com UID! ${onError.toString()}");
      });
      return idValor;
    }else if(id == null){
      await firestore.collection(tabela).add(dado)
          .then((value){
            print("Dado registrado com sucesso! ${value.documentID}");
            idValor = value.documentID;
          })
          .catchError((onError){
            print("Falha ao tentar registrar dado! ${onError.toString()}");
          });
      return idValor;
    }else{
      await firestore.collection(tabela).document(id).setData(dado)
          .then((value){
      print("Dado registrado com sucesso e com ID!");
      idValor = id;
      })
          .catchError((onError){
      print("Falha ao tentar registrar dado com ID! ${onError.toString()}");
      });
      return idValor;
    }
  }

  Future read(String tabela, [String id, bool listen, Map<String, dynamic> dadosListen]) async{
    listen ??= false;//Se for null, recebe false!
    if(listen && listen != null){
      firestore.collection(tabela).snapshots().listen((snapshot) {
        snapshot.documentChanges.forEach((documentChange) {
          if(documentChange.type == DocumentChangeType.added){//Registro Adicionado
            String id = documentChange.document.documentID;
            dadosListen.putIfAbsent(id, () => documentChange.document.data);
            print("Dado adicionado a lista! ${dadosListen[id]}");
          }else if(documentChange.type == DocumentChangeType.modified){//Registro Atualizado
            String id = documentChange.document.documentID;
            dadosListen[id] = documentChange.document.data;
            print("Dado atualizado na lista! ${dadosListen[id]}");
          }else if(documentChange.type == DocumentChangeType.removed){//Registro Removido
            String id = documentChange.document.documentID;
            dadosListen.remove(id);
            print("Dado removido da lista! ${documentChange.document.data}");
          }
        });
      });
    }else{
      if(id == null){
        Map<String, dynamic> dados = new Map();
        QuerySnapshot querySnapshot = await firestore.collection(tabela).getDocuments();
        for(DocumentSnapshot item in querySnapshot.documents){
          dados.putIfAbsent(item.documentID, () => item.data);
        }
        print("Dados lido com sucesso! $dados");
        return dados;
      }else{
        Map<String, dynamic> dado = new Map();
        DocumentSnapshot documentSnapshot = await firestore.collection(tabela).document(id).get();
        dado.putIfAbsent(documentSnapshot.documentID, () => documentSnapshot.data);
        print("Dado lido com sucesso! ${dado[id]}");
        return dado;
      }
    }
  }

  Future update(String tabela, String id, Map<String, dynamic> dado) async{
    FirebaseUser firebaseUser = await firebaseAuth.currentUser();
    id = (id == '')? firebaseUser.uid : id;

    await firestore.collection(tabela).document(id).updateData(dado)
        .then((value){
          print("Dado atualizado com sucesso!");
          return true;
        })
        .catchError((onError){
          print("Falha ao tentar atualizar dado! ${onError.toString()}");
          return false;
        });
  }

  Future delete(String tabela, String id) async{
    FirebaseUser firebaseUser = await firebaseAuth.currentUser();
    id = (id == '')? firebaseUser.uid : id;
    await firestore.collection(tabela).document(id).delete()
        .then((value){
          print("Dado deletado com sucesso!");
          return true;
        })
        .catchError((onError){
          print("Falha ao tentar deletar dado!");
          return false;
        });
  }
}