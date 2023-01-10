import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as Path;
import 'package:modbus/modbus.dart' as modbus;

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
  dynamic shouldUseEth = {};
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
    shouldUseEth = storage.getItem(Helper.useEthKey) ?? {};
    operationData = storage.getItem(Helper.operationKey) ?? [];
    setState(() {
      isLoadedStorage = true;
    });
    updateOperationValue();
  }

  Future<void> updateOperationValue() async {
    try {
      var v = await getVoltage();
      var c = await getCurrent();
      setState(() {
        voltage = v;
        current = c;
      });
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
      await setCurrent();
      await setVoltage();
      await setHv();
      updateOperationValue();
    }
  }

  void openPort() {
    port = SerialPort(Helper.getValueOfKey(rsData, 'com_port'));
    final configu = SerialPortConfig();
    configu.baudRate =
        int.tryParse(Helper.getValueOfKey(rsData, 'baud_rate')) ?? 9600;
    configu.bits =
        int.tryParse(Helper.getValueOfKey(rsData, 'word_length')) ?? 7;
    configu.parity = int.tryParse(Helper.getValueOfKey(rsData, 'parity')) ?? 2;
    configu.stopBits =
        int.tryParse(Helper.getValueOfKey(rsData, 'stop_bits')) ?? 1;
    port.openReadWrite();
    port.config = configu;
  }

  Future<void> setHv() async {
    if (shouldUseEth['value'] == true) {
      setHvEth();
    } else {
      bool on =
          operationFormField[0]['value'].toString() == "on" ? true : false;
      var hvCmd = Helper.getHvOnOffCommand(on);
      var hvPass = Helper.getHvPassword();
      if (rsData.isEmpty == false) {
        openPort();
        try {
          port.write(hvPass);
          var data = port.read(18, timeout: 1000);
          var x = Helper.convertUint8ListToString(data);
          print('Read return after password set is $x');
          port.write(hvCmd);
          data = port.read(18, timeout: 1000);
          x = Helper.convertUint8ListToString(data);
          print('Read return after hv on off $x');
          port.close();
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
        }
      }
    }
  }

  Future<dynamic> useEthernet(
    Future<dynamic> Function(modbus.ModbusClient client) callback,
  ) async {
    var client = Helper.getEthClient(ethData);
    try {
      await client.connect();
      var slaveIdResponse = await client.reportSlaveId();
      StringBuffer sb = StringBuffer();
      slaveIdResponse.forEach((f) {
        sb.write(f.toRadixString(16).padLeft(2, '0'));
        sb.write(" ");
      });
      print("Slave ID: " + sb.toString());
      return callback(client);
    } catch (e) {
      print(e);
      Helper.showToast(
        context,
        'Error in connecting with ethernet',
        isError: true,
      );
    } finally {
      client.close();
    }
  }

  Future<void> setHvEth() async {
    c(modbus.ModbusClient client) async {
      int hvAction = operationFormField[0]['value'].toString() == "on" ? 1 : 0;
      var passwordRegister = Helper.getHvRegister(isPassword: true);
      var hvRegister = Helper.getHvRegister();
      var x = [0x0106, 0x2000];
      // TODO: RP handle password
      await client.writeMultipleRegisters(
          passwordRegister, Uint16List.fromList(x));
      await client.writeSingleRegister(hvRegister, hvAction);
    }

    await useEthernet(c);
  }

  Future<void> setVoltage() async {
    if (shouldUseEth['value'] == true) {
      setVoltageEth();
    } else {
      var v = double.parse(operationFormField[1]['value'].toString());
      if (rsData.isEmpty == false) {
        try {
          port.write(Helper.getVoltagWriteCommand(v));
          var data = port.read(18, timeout: 1000);
          var x = Helper.convertUint8ListToString(data);
          print('Read return after voltage write is $x');
          port.close();
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
        }
      }
    }
  }

  Future<void> setVoltageEth() async {
    c(modbus.ModbusClient client) async {
      var v = double.parse(operationFormField[1]['value'].toString()) * 10;
      int voltageRegister = Helper.getRegister();
      int x = v > 20000 ? 20000 : v.round();
      await client.writeSingleRegister(voltageRegister, x);
    }

    await useEthernet(c);
  }

  Future<void> setCurrent() async {
    if (shouldUseEth['value'] == true) {
      setCurrentEth();
    } else {
      var c = double.parse(operationFormField[2]['value'].toString());
      if (rsData.isEmpty == false) {
        try {
          port.write(Helper.getCurrentWriteCommand(c));
          var data = port.read(18, timeout: 1000);
          var x = Helper.convertUint8ListToString(data);
          print('Read return after current write is $x');
          port.close();
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
        }
      }
    }
  }

  Future<void> setCurrentEth() async {
    c(modbus.ModbusClient client) async {
      var c = double.parse(operationFormField[2]['value'].toString());
      int currentRegister = Helper.getRegister(isVoltage: false);
      int x = c > 60 ? 60 : c.round();
      await client.writeSingleRegister(currentRegister, x);
    }

    await useEthernet(c);
  }

  Future<String> getVoltageEth() async {
    c(modbus.ModbusClient client) async {
      int voltageRegister = Helper.getRegister(isRead: true);
      var registers = await client.readHoldingRegisters(voltageRegister, 1);
      return (registers[0] / 10).toString() + 'V';
    }

    var x = await useEthernet(c);
    return '$x v';
  }

  Future<String> getVoltage() async {
    if (shouldUseEth['value'] == true) {
      return getVoltageEth();
    } else {
      if (rsData.isEmpty == false) {
        try {
          port.write(Helper.getVoltagReadCommand());
          var data = port.read(18, timeout: 1000);
          var x = Helper.convertUint8ListToString(data);
          port.close();
          return Helper.readValueFromHex(x, false);
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
          return '0.0 V';
        }
      }
    }
    return '0.0 V';
  }

  Future<String> getCurrentEth() async {
    c(modbus.ModbusClient client) async {
      int currentRegister = Helper.getRegister(isVoltage: false, isRead: true);
      var registers = await client.readHoldingRegisters(currentRegister, 1);
      return (registers[0] / 10).toString() + 'A';
    }

    var x = await useEthernet(c);
    return '$x A';
  }

  Future<String> getCurrent() async {
    if (shouldUseEth['value'] == true) {
      return getCurrentEth();
    } else {
      if (rsData.isEmpty == false) {
        try {
          port.write(Helper.getCurrentReadCommand());
          var data = port.read(18, timeout: 1000);
          var x = Helper.convertUint8ListToString(data);
          port.close();
          return Helper.readValueFromHex(x, true);
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
          csvDataTOWrite.add([
            'Date',
            'Time',
            'Output Voltsge',
            'Output Current',
          ]);
        } else {
          csvDataTOWrite = x;
        }
      }
      var c = await getCurrent();
      var v = await getVoltage();
      setState(() {
        current = c;
        voltage = v;
      });
      var dateTime = DateTime.now();
      var day = dateTime.year.toString() +
          '-' +
          dateTime.month.toString() +
          '-' +
          dateTime.day.toString();
      var time = dateTime.hour.toString() +
          ':' +
          dateTime.minute.toString() +
          ':' +
          dateTime.second.toString();
      csvDataTOWrite.add([day, time, v, c]);
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
                  constraints: const BoxConstraints(maxWidth: 200),
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
