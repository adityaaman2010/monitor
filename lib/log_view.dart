import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as Path;

import 'helper.dart';

class LogView extends StatefulWidget {
  const LogView({Key? key}) : super(key: key);

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  dynamic dasData = [];
  List<List<dynamic>> logData = [];
  bool storageLoaded = false;
  LocalStorage storage = LocalStorage(Helper.storageName);

  Future<void> loadDas() async {
    await storage.ready;
    dasData = storage.getItem(Helper.dasKey) ?? [];
    await getPreviousSavedFile();
  }

  @override
  initState() {
    super.initState();
    loadDas();
  }

  Future<void> getPreviousSavedFile() async {
    var context = Path.Context(style: Path.Style.windows);
    var x = dasData[1]['value'];
    var y = dasData[2]['value'];
    var z = dasData[3]['value'];
    var filePath = context.join(x, "$y.$z");
    File file = File(filePath);
    if (file.existsSync()) {
      var _stream = file.openRead();
      var fields = await _stream
          .transform(utf8.decoder)
          .transform(CsvToListConverter())
          .toList();
      setState(() {
        logData = fields;
      });
    } else {
      setState(() {
        logData = [];
      });
    }
  }

  Map<int, TableColumnWidth> getTableWidth() {
    Map<int, TableColumnWidth> tc = {};
    for (var i = 0; i < logData.length; i++) {
      tc[i] = const FixedColumnWidth(200);
    }
    return tc;
  }

  List<TableRow> getTableRows() {
    List<TableRow> tr = [];
    for (var i = 0; i < logData.length; i++) {
      if (i == 0) {
        tr.add(TableRow(
          children: getColumns(logData[i], isHeader: true),
        ));
      } else {
        tr.add(TableRow(
          children: getColumns(
            logData[i],
          ),
        ));
      }
    }
    return tr;
  }

  List<Widget> getColumns(List<dynamic> data, {isHeader = false}) {
    var style;
    if (isHeader) {
      style = const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: Colors.black,
      );
    } else {
      style = const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: Colors.black,
      );
    }
    List<Widget> cc = [];
    for (var i = 0; i < data.length; i++) {
      cc.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            data[i],
            style: style,
          ),
        ),
      );
    }
    return cc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Logging'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(),
              columnWidths: getTableWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: getTableRows(),
            ),
          ),
        ),
      ),
    );
  }
}
