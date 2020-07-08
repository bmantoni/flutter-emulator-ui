import 'dart:html';

import 'package:flutter/material.dart';
import 'package:pic_dart_emu/Address.dart';
import 'package:pic_dart_emu/PIC.dart';
import 'package:file_picker_web/file_picker_web.dart';
import 'package:pic_dart_emu/runner.dart';
import 'package:pic_dart_emu/runner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIC Emulator UI',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'PIC Emulator UI'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ProgramRunner _runner = ProgramRunner();
  Address _pc;
  File _program;
  String _emuSpeed = 'Fast';
  int _memoryViewStart = 0;
  var speeds = {'Slow': 100000, 'Medium': 5000, 'Fast': 1};

  get _programMemoryLen => _runner.computer.memory.program.lengthInWords;
  get _isValidProgram => _program != null;
  get _emuSpeedUs => speeds[_emuSpeed];

  @override
  void initState() {
    super.initState();
    _pc = _runner.computer.pc;
    _runner.computer.setNotifyCallback(() {
      setState(() {
        _pc = _runner.computer.pc;
        print(_pc.toString());
      });
    });
  }

  Color getMemoryCellColor(int i) {
    if (i == _pc.asInt()) return Colors.red;
    if (_runner.computer.memory.program
            .getWord(Address.fromInt(i))
            .getUint16(0) !=
        0) return Colors.green;
    return Colors.transparent;
  }

  List<TableRow> getMemoryTableRows() {
    List<TableRow> rows = List<TableRow>(_programMemoryLen - _memoryViewStart);
    for (int i = 0; i < _programMemoryLen - _memoryViewStart; ++i) {
      rows[i] = TableRow(
        children: [Text('', style: TextStyle(height: 0.25))],
        decoration: BoxDecoration(color: getMemoryCellColor(_memoryViewStart + i)));
    }
    return rows;
  }

  Row getFilePickerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        FlatButton(
          onPressed: () async {
            var x = await FilePicker.getFile();
            setState(() {
              _program = x;
            });
          },
          child: Text(
            "Choose Program File",
          ),
        ),
        FlatButton(
          onPressed: _isValidProgram
              ? () {
                  FileReader reader = new FileReader();
                  reader.onLoad.listen((event) {
                    _runner.runProgramString(reader.result,
                        instrDelayUs: _emuSpeedUs);
                  });
                  reader.readAsText(_program);
                }
              : null,
          child: Text(
            _isValidProgram ? "Run Program" : "",
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Text('Program Memory (drag to scroll)'),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.all(20),
                width: 75,
                child: Table(
                  border: TableBorder.all(width: 0.3),
                  children: getMemoryTableRows(),
                ),
              ),
            ],
          ),
        ),
        Container(
            alignment: Alignment.topRight,
            margin: const EdgeInsets.all(40),
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                getFilePickerRow(),
                ListTile(
                  title: const Text('Program Loaded OK?'),
                  trailing: Icon(
                    _isValidProgram ? Icons.check : Icons.block,
                    color: _isValidProgram ? Colors.green : Colors.red,
                    size: 36.0,
                    semanticLabel: 'Valid Program is Loaded',
                  ),
                ),
                ListTile(
                  title: const Text('Emulator Speed'),
                  trailing: DropdownButton<String>(
                    value: _emuSpeed,
                    elevation: 16,
                    onChanged: (String newValue) {
                      setState(() {
                        _emuSpeed = newValue;
                      });
                    },
                    items: <String>['Slow', 'Medium', 'Fast']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ListTile(
                title: const Text('Min Memory Address'),
                trailing: Container(
                  width: 50,
                  child: TextFormField(
                    initialValue: '0000',
                    onFieldSubmitted: (value) {
                      setState(() {
                        _memoryViewStart = int.parse(value);
                      });
                    },
                  ),
                ),
              ),
                ListTile(
                  title: const Text('Program Counter'),
                  trailing: Text(_pc.toString()),
                )
              ],
            )
          )
      ]),
    );
  }
}
