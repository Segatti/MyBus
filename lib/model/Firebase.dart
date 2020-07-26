import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Firebase{
  FirebaseAuth firebaseAuth;
  Firestore firestore;

  //Funções Básicas
  Future create(String tabela, Map<String, dynamic> dado, [bool userId, String id]) async{
    if(id == null){
      firestore.collection(tabela).add(dado)
          .then((value){
            print("Dado registrado com sucesso! ${value.toString()}");
            return true;
          })
          .catchError((onError){
            print("Falha ao tentar registrar dado! ${onError.toString()}");
            return false;
          });
    }else if(userId){
      FirebaseUser firebaseUser = await firebaseAuth.currentUser();
      firestore.collection(tabela).document(firebaseUser.uid).setData(dado)
          .then((value){
            print("Dado registrado com sucesso e com UID!");
            return true;
          })
          .catchError((onError){
            print("Falha ao tentar registrar dado com UID! ${onError.toString()}");
            return false;
          });
    }else{
      firestore.collection(tabela).document(id).setData(dado)
          .then((value){
      print("Dado registrado com sucesso e com ID!");
      return true;
      })
          .catchError((onError){
      print("Falha ao tentar registrar dado com ID! ${onError.toString()}");
      return false;
      });
      }
  }

  Future read(String tabela, [String id, bool listen, Map<String, dynamic> dadosListen]) async{
    if(listen){
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

    firestore.collection(tabela).document(id).updateData(dado)
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
    firestore.collection(tabela).document(id).delete()
        .then((value){
          print("Dado deletado com sucesso!");
          return true;
        })
        .catchError((onError){
          print("Falha ao tentar deletar dado!");
          return false;
        });
  }

  //Funções Primitivas
  Firebase(){
    this.firebaseAuth = FirebaseAuth.instance;
    this.firestore = Firestore.instance;
  }
}