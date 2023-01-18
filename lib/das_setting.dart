import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:localstorage/localstorage.dart';
import 'helper.dart';

class DasSetting extends StatefulWidget {
  const DasSetting({Key? key}) : super(key: key);

  @override
  State<DasSetting> createState() => _DasSettingState();
}

class _DasSettingState extends State<DasSetting> {
  final LocalStorage storage = LocalStorage(Helper.storageName);
  final _dasForm = GlobalKey<FormState>();
  dynamic dasData = [];
  bool isLoadedStorage = false;

  void loadPortConfig() async {
    await storage.ready;
    dasData = storage.getItem(Helper.dasKey) ?? [];
    if (dasData.isEmpty == false) {
      dasFormField[0]['value'] = Helper.getValueOfKey(dasData, 'log_frequency');
      dasFormField[1]['value'] = Helper.getValueOfKey(dasData, 'log_path');
      dasFormField[2]['value'] = Helper.getValueOfKey(dasData, 'log_name');
    }
    setState(() {
      isLoadedStorage = true;
    });
  }

  void _saveForm() async {
    if (_dasForm.currentState!.validate() && dasFormField[1]['value'] != '') {
      _dasForm.currentState!.save();
      await storage.setItem(Helper.dasKey, dasFormField);
      Helper.showToast(
        context,
        'Saved Data Saving Configuration',
      );
    }
    if (dasFormField[1]['value'] == '' && _dasForm.currentState!.validate()) {
      Helper.showToast(context, 'Please select a folder', isError: true);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadPortConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAS Setting'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          widthFactor: 1.5,
          child: Column(
            children: [
              isLoadedStorage ? getDasForm() : Container(),
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
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/operations',
                      );
                    },
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  var dasFormField = [
    {
      'label': 'Data Logging Frequency',
      'key': 'log_frequency',
      'value': '',
      'hint': 'Read Frequency In Seconds (Minimum 2)'
    },
    {
      'label': 'Data Logging Path',
      'key': 'log_path',
      'value': '',
      'hint': 'Logging Folder Path'
    },
    {
      'label': 'Data Logging File Name',
      'key': 'log_name',
      'value': '',
      'hint': 'Logging filename'
    }
  ];

  void browseFile() async {
    var path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      setState(() {
        dasFormField[1]['value'] = path;
      });
    }
  }

  Widget getLogPathText() {
    return dasFormField[1]['value'] != ''
        ? Text(dasFormField[1]['value']!)
        : Helper.getVerticalMargin(0);
  }

  Widget getDasForm() {
    return Expanded(
      child: Form(
        key: _dasForm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dasFormField.map((e) {
              if (e['key'] == 'log_path') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Helper.getVerticalMargin(15.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Data Logging Path',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                        Helper.getHorizontalMargin(15.0),
                        ElevatedButton(
                          onPressed: browseFile,
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
                            foregroundColor:
                                MaterialStateProperty.all(Colors.white),
                          ),
                          child: const Text('Browse'),
                        )
                      ],
                    ),
                    getLogPathText(),
                  ],
                );
              } else {
                return TextFormField(
                  initialValue: e['value'],
                  onSaved: (value) {
                    e["value"] = value!;
                  },
                  decoration: InputDecoration(
                    labelText: e["label"],
                    hintText: e['hint'],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    if (e['key'] == 'log_frequency') {
                      try {
                        var x = int.parse(value);
                        if (x < 2) {
                          return 'Please enter value greater than 1';
                        } else {
                          return null;
                        }
                      } catch (e) {
                        return 'Please enter a valid value';
                      }
                    }
                    return null;
                  },
                );
              }
            }).toList(),
          ),
        ),
      ),
    );
  }
}
