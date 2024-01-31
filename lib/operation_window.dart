import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as Path;
import 'package:modbus/modbus.dart' as modbus;
import 'package:flutter/services.dart';
import 'helper.dart';
import 'constants.dart';

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
  int voltagePicicIndex = 0;

  var operationFormField = [
    {'label': 'High Voltage', 'key': 'high_voltage', 'value': ''},
    {'label': 'Output Voltage Setting', 'key': 'opvs', 'value': ''},
    {'label': 'Output Current Setting', 'key': 'opcs', 'value': ''},
  ];

  var voltagePics = [
    'assets/images/voltage-three.png',
    'assets/images/voltage-two.png',
    'assets/images/voltage-one.png',
  ];

  void loadPortConfig() async {
    await storage.ready;
    rsData = storage.getItem(Helper.rsKey) ?? [];
    ethData = storage.getItem(Helper.ethKey) ?? [];
    dasData = storage.getItem(Helper.dasKey) ?? [];
    shouldUseEth = storage.getItem(Helper.useEthKey) ?? {};
    operationData = storage.getItem(Helper.operationKey) ?? [];
    if (operationData.isEmpty == false) {
      operationFormField[1]['value'] = operationData[1]['value'];
      operationFormField[2]['value'] = operationData[2]['value'];
    }
    await setHvPassword();
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
      updateOperationValue();
    }
  }

  void openPort() {
    port = SerialPort(Helper.getValueOfKey(rsData, 'com_port'));
    final configu = SerialPortConfig();
    configu.baudRate = Helper.getValueOfKey(rsData, 'baud_rate');
    configu.bits = Helper.getValueOfKey(rsData, 'word_length');
    configu.parity = Helper.getValueOfKey(rsData, 'parity');
    configu.stopBits = Helper.getValueOfKey(rsData, 'stop_bits');
    port.openReadWrite();
    port.config = configu;
  }

  Future<void> setHvPassword() async {
    if (shouldUseEth['value'] == true) {
      c(modbus.ModbusClient client) async {
        var passwordRegister = Helper.getHvRegister(isPassword: true);
        await client.writeSingleRegister(passwordRegister, 2006);
      }

      await useEthernet(c);
    } else {
      var hvPass = Helper.getHvPassword();
      if (rsData.isEmpty == false) {
        try {
          openPort();
          port.write(hvPass);
          var data = port.read(18, timeout: 1000);
          var x = Helper.convertUint8ListToString(data);
          print('Read return after password set is $x');
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

  Future<void> setHv(bool on) async {
    await setHvPassword();
    if (shouldUseEth['value'] == true) {
      await setHvEth(on);
      setState(() => highVotage = on ? 'On' : 'Off');
    } else {
      var hvCmd = Helper.getHvOnOffCommand(on);
      if (rsData.isEmpty == false) {
        try {
          openPort();
          port.write(hvCmd);
          var data = port.read(18, timeout: 1000);
          var x = Helper.convertUint8ListToString(data);
          print('Read return after hv on off $x');
          port.close();
          setState(() => highVotage = on ? 'On' : 'Off');
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
      return await callback(client);
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

  Future<void> setHvEth(bool on) async {
    c(modbus.ModbusClient client) async {
      int hvAction = on ? 1 : 0;
      var hvRegister = Helper.getHvRegister();
      await client.writeSingleRegister(hvRegister, hvAction);
    }

    await useEthernet(c);
  }

  Future<void> setVoltage() async {
    if (shouldUseEth['value'] == true) {
      await setVoltageEth();
    } else {
      var v = double.parse(operationFormField[1]['value'].toString());
      if (rsData.isEmpty == false) {
        try {
          openPort();
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
      double multiplier = 0;
      var v = double.parse(operationFormField[1]['value'].toString());
      int voltageRegister = Helper.getRegister();
      if (v >= 2 && v <= 26) {
        multiplier = 2000 + ((v - 2) / (26 - 2)) * (20000 - 2000);
      } else if (v >= 27 && v <= 199) {
        multiplier = 2000 + ((v - 27) / (199 - 27)) * (20000 - 2000);
      } else if (v >= 200 && v <= 2000) {
        multiplier = 2000 + ((v - 200) / (2000 - 200)) * (20000 - 2000);
      } else {
        return "Input out of range";
      }
      int x = multiplier.round();
      // int x = v > 20000 ? 20000 : (v * 10).round();
      print(await client.writeSingleRegister(voltageRegister, x));
    }

    await useEthernet(c);
  }

  Future<void> setCurrent() async {
    if (shouldUseEth['value'] == true) {
      await setCurrentEth();
    } else {
      var c = double.parse(operationFormField[2]['value'].toString());
      if (rsData.isEmpty == false) {
        try {
          openPort();
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
      double numCurrent = 0;
      if (c > 6){
        numCurrent = 6;
      }
      else if(c < 0){
      numCurrent = 0;
      }
      else{
        numCurrent = c;
      }
      
      var currentSingleDecimal = num.parse(numCurrent.toStringAsFixed(1));
      print("Currentsingledecimalis: ${currentSingleDecimal}");
      int x = currentLookup[currentSingleDecimal] ?? 0;
      // int x = c > 60 ? 60 : (c * 10).round();
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
    return '$x';
  }

  Future<String> getVoltage() async {
    if (shouldUseEth['value'] == true) {
      return getVoltageEth();
    } else {
      if (rsData.isEmpty == false) {
        try {
          openPort();
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
    return '$x';
  }

  Future<String> getCurrent() async {
    if (shouldUseEth['value'] == true) {
      return getCurrentEth();
    } else {
      if (rsData.isEmpty == false) {
        try {
          openPort();
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
    try {
      var context = Path.Context(style: Path.Style.windows);
      var x = dasData[1]['value'];
      var y = dasData[2]['value'];
      var filePath = context.join(x, "$y.csv");
      var file = File(filePath);
      String csv = const ListToCsvConverter().convert(data);
      await file.writeAsString(csv);
    } catch (e) {
      print(e);
    }
    ;
  }

  Future<List<List<dynamic>>> getPreviousSavedFile() async {
    try {
      var context = Path.Context(style: Path.Style.windows);
      var x = dasData[1]['value'];
      var y = dasData[2]['value'];
      var filePath = context.join(x, "$y.csv");
      File file = File(filePath);
      if (file.existsSync()) {
        var _stream = file.openRead();
        var fields = await _stream
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();
        return fields;
      } else {
        return [];
      }
    } catch (e) {
      print(e);
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
      var temp_v = await getVoltage();
      String v = getVoltageReadLookup(int.parse(temp_v)); 
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
              crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget getVoltageAndCurrentSection() {
    return Row(
      children: [
        Form(
          key: _operationForm,
          child: Column(children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 200,
              ),
              child: TextFormField(
                initialValue: operationFormField[1]["value"],
                keyboardType: TextInputType.numberWithOptions(decimal: false), // Only allow whole numbers
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Only allow digits
                onSaved: (value) {
                  operationFormField[1]["value"] = value!;
                },
                decoration: InputDecoration(
                  hintText: Helper.getVoltageRange(),
                  labelText: operationFormField[1]["label"],
                ),
                onChanged: (value) {
                  var x = int.parse(value);
                  int i = 0;
                  if (x >= 2 && x <= 26) {
                    i = 0;
                  } else if (x >= 27 && x < 200) {
                    i = 1;
                  } else {
                    i = 2;
                  }
                  setState(() {
                    voltagePicicIndex = i;
                  });
                },
                validator: (value) {
                  try {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    var x = double.parse(value.toString());
                    var z = Helper.getPlcInputRange();
                    if (x >= z[0] && x <= z[1]) {
                      return null;
                    } else {
                      return 'Please value in range ${z[0]}-${z[1]}';
                    }
                  } catch (e) {
                    return 'Please enter valid input';
                  }
                },
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 200,
              ),
              child: TextFormField(
                initialValue: operationFormField[2]["value"],
                keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimal numbers
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$'))], // Allow only one decimal point

                onSaved: (value) {
                  operationFormField[2]["value"] = value!;
                },
                decoration: InputDecoration(
                  hintText: Helper.getCurrentRange(),
                  labelText: operationFormField[2]["label"],
                ),
                validator: (value) {
                  try {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    var x = double.parse(value.toString());
                    var z = Helper.getPlcInputRange(isCurrent: true);
                    if (x >= z[0] && x <= z[1]) {
                      return null;
                    } else {
                      return 'Please enter valid input';
                    }
                  } catch (e) {
                    return 'Please enter valid input';
                  }
                },
              ),
            )
          ]),
        ),
        Helper.getHorizontalMargin(10.0),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 100,
            maxHeight: 100,
          ),
          child: Image.asset(
            voltagePics[voltagePicicIndex],
            fit: BoxFit.cover,
          ),
        )
      ],
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
          Helper.getVerticalMargin(20.0),
          getVoltageAndCurrentSection(),
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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 200,
            minWidth: 200,
          ),
          child: const Text('High Voltage'),
        ),
        ElevatedButton(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 15,
              ),
            ),
            textStyle: MaterialStateProperty.all(
              const TextStyle(
                fontSize: 20.0,
              ),
            ),
            backgroundColor: MaterialStateProperty.all(
              Colors.green[700],
            ),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
          onPressed: (() {
            setHv(true);
          }),
          child: const Text('ON'),
        ),
        Helper.getHorizontalMargin(20),
        ElevatedButton(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 15,
              ),
            ),
            textStyle: MaterialStateProperty.all(
              const TextStyle(
                fontSize: 20.0,
              ),
            ),
            backgroundColor: MaterialStateProperty.all(
              Colors.red[700],
            ),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
          onPressed: (() {
            setHv(false);
          }),
          child: const Text('OFF'),
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
