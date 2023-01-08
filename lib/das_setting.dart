import 'package:flutter/material.dart';
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
      dasFormField[3]['value'] = Helper.getValueOfKey(dasData, 'log_type');
    }
    setState(() {
      isLoadedStorage = true;
    });
  }

  void _saveForm() async {
    if (_dasForm.currentState!.validate()) {
      _dasForm.currentState!.save();
      await storage.setItem(Helper.dasKey, dasFormField);
      Helper.showToast(
        context,
        'Saved Data Saving Configuration',
      );
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
        title: const Text('Das Setting'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Center(
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
      'hint': 'Read Frequency In Seconds'
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
    },
    {
      'label': 'Data Logging File Type',
      'key': 'log_type',
      'value': '',
      'hint': 'Logging file extension ex: csv'
    },
  ];

  Widget getDasForm() {
    return Expanded(
      child: Form(
        key: _dasForm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dasFormField
                .map(
                  (e) => TextFormField(
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
                      return null;
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
