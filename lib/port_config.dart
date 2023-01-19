import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:localstorage/localstorage.dart';

import 'helper.dart';

class PortConfig extends StatefulWidget {
  const PortConfig({Key? key}) : super(key: key);

  @override
  State<PortConfig> createState() => _PortConfigState();
}

class _PortConfigState extends State<PortConfig> {
  final LocalStorage storage = LocalStorage(Helper.storageName);
  var availablePorts = [];
  var port;
  bool portInit = false;
  bool isOpen = false, isLoadedStorage = false;
  static String title = 'Port Configuration';
  final _formKeyRs = GlobalKey<FormState>();
  final _formKeyEthernet = GlobalKey<FormState>();
  var baudRates = [
    300,
    600,
    1200,
    2400,
    4800,
    9600,
    14400,
    19200,
    38400,
    56000,
    57600,
    115200,
    128000,
    230400,
    26000
  ];
  var dataBits = [7, 8];
  var stopBits = [1, 2];

  void loadPortConfig() async {
    await storage.ready;
    var x = storage.getItem(Helper.rsKey) ?? [];
    var y = storage.getItem(Helper.ethKey) ?? [];
    var z = storage.getItem(Helper.useEthKey) ?? {};
    if (x.isEmpty == false) {
      rsFormField[0]['value'] = Helper.getValueOfKey(x, 'com_port');
      rsFormField[1]['value'] = Helper.getValueOfKey(x, 'baud_rate');
      rsFormField[2]['value'] = Helper.getValueOfKey(x, 'word_length');
      rsFormField[3]['value'] = Helper.getValueOfKey(x, 'parity');
      rsFormField[4]['value'] = Helper.getValueOfKey(x, 'stop_bits');
    }
    if (y.isEmpty == false) {
      ethernetField[0]['value'] = Helper.getValueOfKey(y, 'ip_address');
      ethernetField[1]['value'] = Helper.getValueOfKey(y, 'service_port');
    }
    if (z.isEmpty == false) {
      shouldUseEth = z;
    }
    setState(() {
      isLoadedStorage = true;
    });
  }

  @override
  void initState() {
    super.initState();
    initPorts();
    loadPortConfig();
  }

  void initPorts() async {
    setState(() {
      var x = {...SerialPort.availablePorts};
      availablePorts = x.toList();
    });
  }

  void _saveForm() async {
    if (_formKeyRs.currentState!.validate()) {
      var saveRs = false;
      if ((rsFormField[0]['value'] == '' && availablePorts.isEmpty == false)) {
        rsFormField[0]['value'] = availablePorts[0];
        saveRs = true;
      } else if (rsFormField[0]['value'] != '') {
        saveRs = true;
      }
      if (saveRs) {
        _formKeyRs.currentState!.save();
        await storage.setItem(Helper.rsKey, rsFormField);
        Helper.showToast(
          context,
          'Saved RS 232 Configuration',
        );
      }
    }
    if (_formKeyEthernet.currentState!.validate()) {
      _formKeyEthernet.currentState!.save();
      await storage.setItem(Helper.ethKey, ethernetField);
      Helper.showToast(
        context,
        'Saved Ethernet Configuration',
      );
    }
  }

  void nextPage() async {
    var x = storage.getItem(Helper.rsKey) ?? [];
    var y = storage.getItem(Helper.ethKey) ?? [];
    if (x.isEmpty && y.isEmpty) {
      Helper.showError(
        context,
        'Incomplete Form',
        'Please fill in atleast one connection details',
      );
    } else if (shouldUseEth['value'] == true && y.isEmpty) {
      Helper.showError(
        context,
        'Incomplete Form',
        'You have enabled Ethernet connection but the form is blank.',
      );
    } else if (shouldUseEth['value'] == false && x.isEmpty) {
      Helper.showError(
        context,
        'Incomplete Form',
        'You have disabled Ethernet connection but the RS232 form is blank.',
      );
    } else {
      await storage.setItem(Helper.useEthKey, shouldUseEth);
      Navigator.pushNamed(
        context,
        '/das_setting',
      );
    }
  }

  Widget getEthRadio() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Expanded(
          flex: 1,
          child: Text('Connect with ethernet'),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Radio<bool>(
                  value: false,
                  activeColor: Colors.redAccent,
                  fillColor: const MaterialStatePropertyAll(Colors.blueAccent),
                  groupValue: shouldUseEth['value'],
                  onChanged: (index) {
                    setState(() {
                      shouldUseEth['value'] = false;
                    });
                  }),
              const Expanded(
                child: Text('No'),
              )
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Radio<bool>(
                  value: true,
                  activeColor: Colors.redAccent,
                  fillColor: const MaterialStatePropertyAll(Colors.blueAccent),
                  groupValue: shouldUseEth['value'],
                  onChanged: (index) {
                    setState(() {
                      shouldUseEth['value'] = true;
                    });
                  }),
              const Expanded(child: Text('Yes'))
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Container(
        constraints: const BoxConstraints(minHeight: 850.0),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: isLoadedStorage
                    ? [
                        getRsColumn(),
                        getEthernetColumn(),
                      ]
                    : [],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                      Colors.blueAccent[700],
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: _saveForm,
                  child: const Text('Save'),
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
                  onPressed: nextPage,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: initPorts,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  static const columnTitleStyle = TextStyle(
    color: Colors.black,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );

  var rsFormField = [
    {'label': 'Com Port', 'key': 'com_port', 'value': ''},
    {'label': 'Baud Rate', 'key': 'baud_rate', 'value': 9600},
    {'label': 'Word Length', 'key': 'word_length', 'value': 7},
    {'label': 'Parity', 'key': 'parity', 'value': 0},
    {'label': 'Stop Bits', 'key': 'stop_bits', 'value': 1},
  ];

  dynamic shouldUseEth = {'value': false};

  var ethernetField = [
    {'label': 'IP Address', 'key': 'ip_address', 'value': ''},
    {'label': 'Service Port', 'key': 'service_port', 'value': ''},
  ];

  Widget getDropDownRs(List<int> x, dynamic e) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: e['label'],
        ),
        child: ButtonTheme(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          child: DropdownButton<int>(
            value: e["value"],
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.deepPurple),
            underline: null,
            onChanged: (int? value) {
              // This is called when the user selects an item.
              setState(() {
                e["value"] = value!;
              });
            },
            items: x.map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value.toString()),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget getRsColumn() {
    return Expanded(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 600.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1.  RS232',
                textAlign: TextAlign.center,
                style: columnTitleStyle,
              ),
              Helper.getVerticalMargin(50.0),
              Form(
                key: _formKeyRs,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rsFormField.map((e) {
                      if (e['key'] == 'com_port') {
                        if (availablePorts.isEmpty) {
                          return const Text('Not available');
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(0),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Com Port',
                              ),
                              child: ButtonTheme(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  child: DropdownButton<String>(
                                    value: e["value"] != ''
                                        ? e["value"]
                                        : availablePorts[0],
                                    icon: const Icon(Icons.arrow_downward),
                                    elevation: 16,
                                    style: const TextStyle(
                                        color: Colors.deepPurple),
                                    underline: null,
                                    onChanged: (String? value) {
                                      // This is called when the user selects an item.
                                      setState(() {
                                        e["value"] = value!;
                                      });
                                    },
                                    items: availablePorts
                                        .map<DropdownMenuItem<String>>(
                                            (dynamic value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  )),
                            ),
                          );
                        }
                      } else if (e['key'] == 'parity') {
                        return Padding(
                          padding: const EdgeInsets.all(0),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Parity',
                            ),
                            child: ButtonTheme(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              child: DropdownButton<String>(
                                value: e["value"].toString(),
                                icon: const Icon(Icons.arrow_downward),
                                elevation: 16,
                                style:
                                    const TextStyle(color: Colors.deepPurple),
                                underline: null,
                                onChanged: (String? value) {
                                  setState(() {
                                    e["value"] = value!;
                                  });
                                },
                                items: [0, 1, 2]
                                    .map<DropdownMenuItem<String>>((int value) {
                                  return DropdownMenuItem<String>(
                                    value: value.toString(),
                                    child: Text(
                                      value.toString() == '0'
                                          ? 'None'
                                          : (value.toString() == '1'
                                              ? 'Odd'
                                              : 'Even'),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      } else if (e['key'] == 'word_length') {
                        return getDropDownRs(dataBits, e);
                      } else if (e['key'] == 'stop_bits') {
                        return getDropDownRs(stopBits, e);
                      } else {
                        return getDropDownRs(baudRates, e);
                      }
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getEthernetColumn() {
    return Expanded(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2.  Ethernet Port',
              textAlign: TextAlign.center,
              style: columnTitleStyle,
            ),
            Helper.getVerticalMargin(50.0),
            getEthRadio(),
            Helper.getVerticalMargin(20.0),
            Form(
              key: _formKeyEthernet,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: ethernetField
                      .map((e) => TextFormField(
                            initialValue: e["value"],
                            onSaved: (value) {
                              e["value"] = value!;
                            },
                            decoration: InputDecoration(
                              labelText: e["label"],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SerialModbus {
  late SerialPort port;
  bool portInit = false;
  bool readWriteInit = false;

  Map commands = {
    "readVoltage": "",
    "setVoltage": "0106109B",
    "readCurrent": "",
    "setCurrent": "",
    "setHVOnOff": "",
    "writePassword": "",
  };

  SerialModbus(String comPort, int baud, int bits, int parity, int stopbits) {
    port = SerialPort(comPort);
    final configu = SerialPortConfig();
    configu.baudRate = baud;
    configu.bits = bits;
    configu.parity = parity;
    configu.stopBits = stopbits;
    port.config = configu;
    portInit = true;
    readWriteInit = port.openReadWrite();
  }

  bool serialWrite(Uint8List data) {
    int bytesWritten = port.write(data);
    if (bytesWritten == data.length) {
      return true;
    } else {
      return false;
    }
  }

  Uint8List serialRead(int bytesLength) {
    Uint8List bytesRead = port.read(bytesLength, timeout: 1000);
    String readChars = Helper.convertUint8ListToString(bytesRead);
    if (checkLRCValid(readChars)) {
      return bytesRead;
    } else {
      return Uint8List(0);
    }
  }

  bool setVoltage(double voltage) {
    var y = '';
    if (voltage * 10 > 20000) {
      voltage = 20000;
      y = voltage.round().toRadixString(16).toUpperCase();
      print("write voltage is");
      print(y);
    } else {
      y = (voltage * 10).round().toRadixString(16).toUpperCase();
      print("write voltage is");
      print(y);
    }
    var x = '$commands["setVoltage"]$y';
    var lrc = Helper.computeLRC(x);
    var data = ':$x$lrc\r\n';
    print(data);

    var dataToSend = Helper.convertStringToUint8List(data);
    Uint8List response = Uint8List(18);
    if (serialWrite(dataToSend)) {
      response = serialRead(18);
      print(Helper.convertUint8ListToString(response));
    }

    return false;
  }

  bool setCurrent(String data) {
    return false;
  }

  bool readVoltage() {
    return false;
  }

  bool readCurrent() {
    return false;
  }

  bool setHV() {
    return false;
  }

  bool writePassword() {
    return false;
  }

  bool checkLRCValid(String dataString) {
    String receivedLRC =
        dataString.substring(dataString.length - 4, dataString.length - 2);
    if (computeLRC(dataString.substring(1, dataString.length - 4)) ==
        receivedLRC) {
      return true;
    } else {
      return false;
    }
  }

  String computeLRC(String string_data) {
    List<int> data = [];
    for (int i = 0; i < string_data.length; i = i + 2) {
      data.add(int.parse(string_data.substring(i, i + 2), radix: 16));
    }

    int lrc = 0; // initial value for the Modbus LRC
    for (int i = 0; i < data.length; i++) {
      lrc += data[i];
    }
    lrc = lrc & 0xff; // mask the result to 8 bits
    lrc = (lrc ^ 0xff) + 1; // invert the bits and add 1
    return lrc.toRadixString(16).toUpperCase();
  }
}
