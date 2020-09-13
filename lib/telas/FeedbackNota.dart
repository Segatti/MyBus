import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mybus/model/FeedBack.dart';

class FeedbackNota extends StatefulWidget {
  @override
  _FeedbackNotaState createState() => _FeedbackNotaState();
}

class _FeedbackNotaState extends State<FeedbackNota> {

  double _nota;
  TextEditingController _msg = TextEditingController();

  _validaDados(){
    print("_validaDados - Inicio");
    double star = _nota;
    String msg = _msg.text;

    if(msg.trim().isNotEmpty && star != 0){
      _enviarDados();
    }
    print("_validaDados - Fim");
  }

  _enviarDados() async {
    print("_enviarDados - Inicio");
    double star = _nota;
    String msg = _msg.text;

    FeedBack feedBack = new FeedBack('', star, msg);
    await feedBack.create();

    Navigator.pop(context);
    print("_enviarDados - Fim");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enviar Feedback"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              //crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 4, 0, 10),
                  child: Text(
                    "Nota do aplicativo",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                  child: RatingBar(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      print(rating);
                      _nota = rating;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: Text(
                    "Mensagem",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 25),
                  child: TextField(
                    controller: _msg,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                ),
                RaisedButton(
                  child: Text(
                    "Enviar",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                  color: Color(0xff1ebbd8),
                  onPressed: (){
                    _validaDados();
                  },
                )
              ],
            ),
          ),
      ),
    );
  }
}
