import 'package:flutter/material.dart';
import 'helper.dart';

class DasSetting extends StatefulWidget {
  const DasSetting({Key? key}) : super(key: key);

  @override
  State<DasSetting> createState() => _DasSettingState();
}

class _DasSettingState extends State<DasSetting> {
  final _dasForm = GlobalKey<FormState>();

  void _saveForm() {
    if (_dasForm.currentState!.validate()) {
      _dasForm.currentState!.save();
    }
    print(dasFormField);
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
              getDasForm(),
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
                    onPressed: null,
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
    {'label': 'Data Logging Frequency', 'key': 'log_frequency', 'value': ''},
    {'label': 'Data Logging Path', 'key': 'log_path', 'value': ''},
    {'label': 'Data Logging File Name', 'key': 'log_name', 'value': ''},
    {'label': 'Data Logging File Type', 'key': 'log_type', 'value': ''},
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
    );
  }
}
