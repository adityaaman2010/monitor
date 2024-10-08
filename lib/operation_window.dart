import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as Path;

import 'helper.dart';

class OperationWindow extends StatefulWidget {
  const OperationWindow({Key? key}) : super(key: key);

  @override
  State<OperationWindow> createState() => _OperationWindowState();
}

class _OperationWindowState extends State<OperationWindow> {
  final LocalStorage storage = LocalStorage(Helper.storageName);
  List<List<dynamic>> csvDataTOWrite = [];
  SerialPort port = SerialPort('name');
  dynamic rsData = [];
  dynamic ethData = [];
  dynamic dasData = [];
  dynamic operationData = [];
  final _operationForm = GlobalKey<FormState>();
  String voltage = '', current = '', highVotage = 'Off';
  bool logData = false, isLoadedStorage = false;

  var operationFormField = [
    {'label': 'High Voltage', 'key': 'high_voltage', 'value': ''},
    {'label': 'Output Voltage Setting', 'key': 'opvs', 'value': ''},
    {'label': 'Output Current Setting', 'key': 'opcs', 'value': ''},
  ];

  void loadPortConfig() async {
    await storage.ready;
    rsData = storage.getItem(Helper.rsKey) ?? [];
    ethData = storage.getItem(Helper.ethKey) ?? [];
    dasData = storage.getItem(Helper.dasKey) ?? [];
    operationData = storage.getItem(Helper.operationKey) ?? [];
    setState(() {
      isLoadedStorage = true;
    });
    updateOperationValue();
  }

  void updateOperationValue() async {
    try {
      voltage = await getVoltage();
      current = await getCurrent();
    } catch (e) {}
  }

  @override
  initState() {
    super.initState();
    loadPortConfig();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    logData = false;
    try {
      port.close();
    } catch (e) {}
  }

  void _saveForm() async {
    if (_operationForm.currentState!.validate()) {
      _operationForm.currentState!.save();
      await storage.setItem(Helper.operationKey, operationFormField);
      Helper.showToast(
        context,
        'Saved Operational Settings',
      );
    }
  }

  Future<String> getVoltage() async {
    if (rsData.isEmpty == false) {
      port = SerialPort(Helper.getValueOfKey(rsData, 'com_port'));
      final configu = SerialPortConfig();
      configu.baudRate =
          int.tryParse(Helper.getValueOfKey(rsData, 'baud_rate')) ?? 9600;
      configu.bits =
          int.tryParse(Helper.getValueOfKey(rsData, 'word_length')) ?? 7;
      configu.parity =
          int.tryParse(Helper.getValueOfKey(rsData, 'parity')) ?? 2;
      configu.stopBits =
          int.tryParse(Helper.getValueOfKey(rsData, 'stop_bits')) ?? 1;
      port.config = configu;
      try {
        port.openReadWrite();
        var reader = SerialPortReader(port);
        port.write(Helper.getVoltagReadCommand());
        await for (var data in reader.stream) {
          var x = Helper.convertUint8ListToString(data);
          reader.close();
          port.close();
          return Helper.readValueFromHex(x, false);
        }
      } catch (e) {
        print(e);
        Helper.showToast(
          context,
          'Error in connecting with serial port.',
          isError: true,
        );
        if (port.isOpen) {
          port.close();
        }
        return '0.0 v';
      }
    }
    return '0.0 v';
  }

  Future<String> getCurrent() async {
    if (rsData.isEmpty == false) {
      port = SerialPort(Helper.getValueOfKey(rsData, 'com_port'));
      final configu = SerialPortConfig();
      configu.baudRate =
          int.tryParse(Helper.getValueOfKey(rsData, 'baud_rate')) ?? 9600;
      configu.bits =
          int.tryParse(Helper.getValueOfKey(rsData, 'word_length')) ?? 7;
      configu.parity =
          int.tryParse(Helper.getValueOfKey(rsData, 'parity')) ?? 2;
      configu.stopBits =
          int.tryParse(Helper.getValueOfKey(rsData, 'stop_bits')) ?? 1;
      port.config = configu;
      try {
        port.openReadWrite();
        var reader = SerialPortReader(port);
        port.write(Helper.getCurrentReadCommand());
        await for (var data in reader.stream) {
          var x = Helper.convertUint8ListToString(data);
          reader.close();
          port.close();
          return Helper.readValueFromHex(x, true);
        }
      } catch (e) {
        print(e);
        Helper.showToast(
          context,
          'Error in connecting with serial port.',
          isError: true,
        );
        if (port.isOpen) {
          port.close();
        }
        return '0.0 A';
      }
    }
    return '0.0 A';
  }

  Future<void> saveLoggingFile(List<List<dynamic>> data) async {
    var context = Path.Context(style: Path.Style.windows);
    var x = dasData[1]['value'];
    var y = dasData[2]['value'];
    var z = dasData[3]['value'];
    var filePath = context.join(x, "$y.$z");
    var file = File(filePath);
    String csv = const ListToCsvConverter().convert(data);
    await file.writeAsString(csv);
  }

  Future<List<List<dynamic>>> getPreviousSavedFile() async {
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
      return fields;
    } else {
      return [];
    }
  }

  void startDataLogging() async {
    if (logData) {
      return;
    }
    logData = true;
    Helper.showToast(context, 'Started data logging');
    while (logData) {
      if (csvDataTOWrite.isEmpty) {
        var x = await getPreviousSavedFile();
        if (x.isEmpty) {
          csvDataTOWrite.add(['firstname', 'lastname', 'random']);
        } else {
          csvDataTOWrite = x;
        }
      }
      csvDataTOWrite.add([
        Helper.getRandomString(10),
        Helper.getRandomString(10),
        Helper.getRandomString(10)
      ]);
      await saveLoggingFile(csvDataTOWrite);
      await Future.delayed(Duration(seconds: int.parse(dasData[0]['value'])));
    }
  }

  void stopDataLogging() {
    logData = false;
    Helper.showToast(context, 'Stopped data logging');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational Window'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: isLoadedStorage
                  ? [
                      getControlSection(),
                      getMonitoringSection(),
                    ]
                  : [],
            ),
            Expanded(
              child: Row(children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 200),
                  child: Text(
                    'Data Logging:  ',
                    style: getStyle(),
                  ),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 15.0,
                      ),
                    ),
                    textStyle: MaterialStateProperty.all(
                      const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all(
                      Colors.greenAccent[700],
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: startDataLogging,
                  child: const Text('Start'),
                ),
                Helper.getHorizontalMargin(15),
                ElevatedButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 15.0,
                      ),
                    ),
                    textStyle: MaterialStateProperty.all(
                      const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all(
                      Colors.redAccent[700],
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: stopDataLogging,
                  child: const Text('Stop'),
                ),
              ]),
            ),
            Helper.getHorizontalMargin(20.0),
            ElevatedButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 25.0,
                  ),
                ),
                textStyle: MaterialStateProperty.all(
                  const TextStyle(
                    fontSize: 24.0,
                  ),
                ),
                backgroundColor: MaterialStateProperty.all(
                  Colors.orangeAccent[700],
                ),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/log_view',
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget getControlSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getTitleText('Control Section'),
          Helper.getVerticalMargin(50),
          getVoltageLabel(),
          Form(
            key: _operationForm,
            child: Column(children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                ),
                child: TextFormField(
                  initialValue: operationData[1]["value"],
                  onSaved: (value) {
                    operationFormField[1]["value"] = value!;
                  },
                  decoration: InputDecoration(
                    labelText: operationFormField[1]["label"],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                ),
                child: TextFormField(
                  initialValue: operationData[2]["value"],
                  onSaved: (value) {
                    operationFormField[2]["value"] = value!;
                  },
                  decoration: InputDecoration(
                    labelText: operationFormField[2]["label"],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
              )
            ]),
          ),
          Helper.getVerticalMargin(20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 15.0,
                    ),
                  ),
                  textStyle: MaterialStateProperty.all(
                    const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  backgroundColor: MaterialStateProperty.all(
                    Colors.blueAccent[700],
                  ),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
                onPressed: _saveForm,
                child: const Text('Save'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget getVoltageLabel() {
    var x = operationFormField[0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Expanded(
          flex: 1,
          child: Text('High Voltage'),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Radio<String>(
                  value: 'on',
                  activeColor: Colors.redAccent,
                  fillColor: const MaterialStatePropertyAll(Colors.blueAccent),
                  groupValue: operationFormField[0]['value'],
                  onChanged: (index) {
                    setState(() {
                      operationFormField[0]['value'] = 'on';
                    });
                  }),
              const Expanded(
                child: Text('On'),
              )
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Radio<String>(
                  value: 'off',
                  activeColor: Colors.redAccent,
                  fillColor: const MaterialStatePropertyAll(Colors.blueAccent),
                  groupValue: operationFormField[0]['value'],
                  onChanged: (index) {
                    setState(() {
                      operationFormField[0]['value'] = 'off';
                    });
                  }),
              const Expanded(child: Text('Off'))
            ],
          ),
        ),
      ],
    );
  }

  Widget getMonitoringSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getTitleText('Monitoring Section'),
          Helper.getVerticalMargin(35),
          Text(
            'High Voltage:  $highVotage',
            style: getStyle(),
          ),
          Helper.getVerticalMargin(15.0),
          Text(
            'Output Voltage:  $voltage',
            style: getStyle(),
          ),
          Helper.getVerticalMargin(15.0),
          Text(
            'Output Current:  $current',
            style: getStyle(),
          ),
        ],
      ),
    );
  }

  TextStyle getStyle() {
    return const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 20,
    );
  }

  Text getTitleText(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    );
  }
}
