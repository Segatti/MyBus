import 'package:flutter/material.dart';

class Horarios extends StatefulWidget {
  @override
  _HorariosState createState() => _HorariosState();
}

class _HorariosState extends State<Horarios> {

  _criarLinhaTable(String listaNomes) {
    return TableRow(
      children: listaNomes.split(',').map((name) {
        return Container(
          alignment: Alignment.center,
          child: Text(
            name,
            style: TextStyle(fontSize: 20.0),
          ),
          padding: EdgeInsets.all(8.0),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Horários UNIFESSPA",
          style: TextStyle(
            fontSize: 18
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(
              color: Colors.black,
              style: BorderStyle.solid,
              width: 1.0,
            ),
            verticalInside: BorderSide(
              color: Colors.black,
              style: BorderStyle.solid,
              width: 1.0,
            ),
          ),
          children: [
            _criarLinhaTable("Campus I, ====>, Campus III"),
            _criarLinhaTable("-------,-------,-------"),
            _criarLinhaTable("Segunda, à, Sexta"),
            _criarLinhaTable("Saída, Chegada, Qtd."),
            _criarLinhaTable("7:30, 07:45, 1"),
            _criarLinhaTable("8:10, 08:25, 2"),
            _criarLinhaTable("8:50, 09:05, 1"),
            _criarLinhaTable("11:55, 12:10, 2"),
            _criarLinhaTable("12:35, 12:50, 1"),
            _criarLinhaTable("13:15, 13:30, 2"),
            _criarLinhaTable("14:00, 14:15, 2"),
            _criarLinhaTable("14:40, 14:55, 1"),
            _criarLinhaTable("17:40, 17:55, 2"),
            _criarLinhaTable("18:20, 18:35, 2"),
            _criarLinhaTable("19:15, 19:30, 1"),
            _criarLinhaTable("-------,-------,-------"),
            _criarLinhaTable(", Sábado, "),
            _criarLinhaTable("Saída, Chegada, Qtd."),
            _criarLinhaTable("8:00, 8:15, 1"),
            _criarLinhaTable("-------,-------,-------"),
            _criarLinhaTable("Campus III, ====>, Campus I"),
            _criarLinhaTable("-------,-------,-------"),
            _criarLinhaTable("Segunda, à, Sexta"),
            _criarLinhaTable("Saída, Chegada, Qtd."),
            _criarLinhaTable("7:50, 08:05, 1"),
            _criarLinhaTable("8:30, 08:45, 1"),
            _criarLinhaTable("11:35, 11:50, 2"),
            _criarLinhaTable("12:15, 12:30, 2"),
            _criarLinhaTable("12:55, 13:10, 1"),
            _criarLinhaTable("13:35, 13:50, 2"),
            _criarLinhaTable("14:20, 14:35, 1"),
            _criarLinhaTable("17:20, 17:35, 2"),
            _criarLinhaTable("18:00, 18:15, 2"),
            _criarLinhaTable("18:55, 19:10, 1"),
            _criarLinhaTable("22:00, 22:15, 2"),
            _criarLinhaTable("-------,-------,-------"),
            _criarLinhaTable(", Sábado,"),
            _criarLinhaTable("Saída, Chegada, Qtd."),
            _criarLinhaTable("12:00, 12:15, 1"),
          ],
        ),
      )
    );
  }
}
