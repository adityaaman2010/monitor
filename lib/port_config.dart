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
  bool isOpen = false, isLoadedStorage = false;
  static String title = 'Port Configuration';
  final _formKeyRs = GlobalKey<FormState>();
  final _formKeyEthernet = GlobalKey<FormState>();

  void loadPortConfig() async {
    await storage.ready;
    var x = storage.getItem(Helper.rsKey) ?? [];
    var y = storage.getItem(Helper.ethKey) ?? [];
    if (x.isEmpty == false) {
      rsFormField[0]['value'] = Helper.getValueOfKey(x, 'com_port');
      rsFormField[1]['value'] = Helper.getValueOfKey(x, 'baud_rate');
      rsFormField[2]['value'] = Helper.getValueOfKey(x, 'word_length');
      rsFormField[3]['value'] =
          rsFormField[4]['value'] = Helper.getValueOfKey(x, 'stop_bits');
    }
    if (y.isEmpty == false) {
      ethernetField[0]['value'] = Helper.getValueOfKey(y, 'ip_address');
      ethernetField[1]['value'] = Helper.getValueOfKey(y, 'service_port');
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
    setState(() => availablePorts = SerialPort.availablePorts);
    // final name = SerialPort.availablePorts.first;
    // var port = SerialPort(name);
    // final configu = SerialPortConfig();
    // configu.baudRate = 9600;
    // configu.bits = 7;
    // configu.parity = 2;
    // configu.stopBits = 1;
    // port.config = configu;
    // SerialPortReader reader = SerialPortReader(port);
    // try {
    //   port.openReadWrite();
    //   print(Helper.getVoltagReadCommand());
    //   var y =
    //       port.write(Helper.convertStringToUint8List(':0106109C00004D\r\n'));
    //   print(y);
    //   reader.stream.listen((data) {
    //     var x = Helper.convertUint8ListToString(data);
    //     reader.close();
    //     port.close();
    //     print('received is $x');
    //   });
    // } catch (e) {
    //   print('*****************');
    //   port.close();
    //   print('error in serial port');
    //   print(e);
    //   print('=================');
    // }
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

  void nextPage() {
    var x = storage.getItem(Helper.rsKey) ?? [];
    var y = storage.getItem(Helper.ethKey) ?? [];
    if (x.isEmpty && y.isEmpty) {
      Helper.showError(
        context,
        'Incomplete Form',
        'Please fill in atleast one connection details',
      );
    } else {
      Navigator.pushNamed(
        context,
        '/das_setting',
      );
    }
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
    {'label': 'Baud Rate', 'key': 'baud_rate', 'value': ''},
    {'label': 'Word Length', 'key': 'word_length', 'value': ''},
    {'label': 'Parity', 'key': 'parity', 'value': 0},
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
                                    value: availablePorts[0],
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
                                  // This is called when the user selects an item.
                                  setState(() {
                                    e["value"] = value!;
                                  });
                                },
                                items: [0, 1, 2]
                                    .map<DropdownMenuItem<String>>((int value) {
                                  return DropdownMenuItem<String>(
                                    value: value.toString(),
                                    child: Text(
                                      value == 0
                                          ? 'None'
                                          : (value == 1 ? 'Odd' : 'Even'),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return TextFormField(
                          initialValue: e['value'].toString(),
                          onSaved: (value) {
                            e["value"] = value!;
                          },
                          decoration: InputDecoration(
                            labelText: e["label"].toString(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        );
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
