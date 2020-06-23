import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _conTarefa = new TextEditingController();
  List _aFazer = [];
  Map<String, dynamic> _ultimoRemovido;
  int _posicao;

  @override
  void initState() {
    super.initState();
    print(DateTime.now());
    _lerDados().then((dados) {
      setState(() {
        _aFazer = json.decode(dados);
      });
    });
  }

  void _adicionarTarefa() {
    Map<String, dynamic> novaTarefa = Map();
    novaTarefa["Titulo"] = _conTarefa.text;
    novaTarefa["Concluido"] = false;

    setState(() {
      _aFazer.add(novaTarefa);
    });

    _salvarDados();
    _conTarefa.text = "";
  }

  Future<void> _recarregar() async {
    await Future.delayed(Duration(seconds: 1));

    _aFazer.sort((a, b) {
      if (a["Concluido"] && !b["Concluido"]) return 1;
      else if (!a["Concluido"] && b["Concluido"]) return -1;
      return 0;
    });

    setState((){});
    _salvarDados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _conTarefa,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(
                        color: Colors.blueAccent
                      )
                    )
                  )
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _adicionarTarefa,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _aFazer.length,
                itemBuilder: _construirItem
              ), 
              onRefresh: _recarregar
            )
          )
        ],
      )
    );
  }

  Widget _construirItem(contexto, indice) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      child: CheckboxListTile(
        title: Text(_aFazer[indice]["Titulo"]),
        value: _aFazer[indice]["Concluido"],
        onChanged: (valor){
          setState(() {
            _aFazer[indice]["Concluido"] = valor;
          });
          _salvarDados();
        },
        secondary: CircleAvatar(
          child: Icon(_aFazer[indice]["Concluido"] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direcao) {
        Scaffold.of(contexto).removeCurrentSnackBar();

        _ultimoRemovido = _aFazer[indice];
        _posicao = indice;

        _aFazer.removeAt(indice);
        _salvarDados();

        final snack = SnackBar(
          content: Text("Tarefa \"${_ultimoRemovido["Titulo"]}\" removida!"),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: "Desfazer", 
            onPressed: () {
              _aFazer.insert(_posicao, _ultimoRemovido);
              _salvarDados();

              setState(() {});
            }
          ),
        );

        Scaffold.of(contexto).showSnackBar(snack);
      },
    );
  }

  Future<File> _pegarArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/dados.json");
  }

  Future<File> _salvarDados() async {
    String dados = jsonEncode(_aFazer);
    final arquivo = await _pegarArquivo();
    return arquivo.writeAsString(dados);
  }

  Future<String> _lerDados() async {
    try {
      final arquivo = await _pegarArquivo();
      return arquivo.readAsString();
    } catch (excecao) {
      return null;
    }
  }
}