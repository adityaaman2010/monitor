import 'package:crc/crc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'helper.dart';

class PortConfig extends StatefulWidget {
  const PortConfig({Key? key}) : super(key: key);

  @override
  State<PortConfig> createState() => _PortConfigState();
}

class _PortConfigState extends State<PortConfig> {
  var availablePorts = [];
  bool isOpen = false;
  static String title = 'Port Configuration';
  final _formKeyRs = GlobalKey<FormState>();
  final _formKeyEthernet = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    initPorts();
  }

  void initPorts() {
    setState(() => availablePorts = SerialPort.availablePorts);
    final name = SerialPort.availablePorts.first;
    final port = SerialPort(name);
    final configu = SerialPortConfig();
    configu.baudRate = 9600;
    configu.bits = 7;
    configu.parity = 2;
    configu.stopBits = 1;
    port.config = configu;
    try {
      if (!isOpen) {
        print('****************');
        print("going on port open");
        isOpen = port.openReadWrite();
      }
      print(port.write(Helper.convertStringToUint8List(':01031096000155\r\n')));
      var data = port.read(15, timeout: 10000);
      var x = Helper.convertUint8ListToString(data);
      print('received: $x');
    } catch (e) {
      print('error in serial port');
      print(e);
      print(SerialPort.lastError);
      print('=================');
      port.close();
    }
  }

  void _saveForm() {
    if (_formKeyRs.currentState!.validate()) {
      _formKeyRs.currentState!.save();
    }
    if (_formKeyEthernet.currentState!.validate()) {
      _formKeyEthernet.currentState!.save();
    }
  }

  void nextPage() {
    Navigator.pushNamed(context, '/das_setting');
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
                children: [
                  getRsColumn(),
                  getEthernetColumn(),
                ],
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
                )
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
    {'label': 'Baud Rate', 'key': 'baud_rate', 'value': ''},
    {'label': 'Word Length', 'key': 'word_length', 'value': ''},
    {'label': 'Parity', 'key': 'parity', 'value': ''},
    {'label': 'Stop Bits', 'key': 'stop_bits', 'value': ''},
  ];

  var ethernetField = [
    {'label': 'IP Address', 'key': 'ip_address', 'value': ''},
    {'label': 'Service Port', 'key': 'service_port', 'value': ''},
  ];

  Widget getRsColumn() {
    return Expanded(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 600.0,
          ),
          child: Column(
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
                    children: rsFormField
                        .map((e) => TextFormField(
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
      ),
    );
  }

  Widget getEthernetColumn() {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            const Text(
              '2.  Ethernet Port',
              textAlign: TextAlign.center,
              style: columnTitleStyle,
            ),
            Helper.getVerticalMargin(50.0),
            Form(
              key: _formKeyEthernet,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: ethernetField
                      .map((e) => TextFormField(
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
