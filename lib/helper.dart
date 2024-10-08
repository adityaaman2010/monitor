import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:fluttertoast/fluttertoast.dart';

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

class Helper {
  static String storageName = 'monitor_app';
  static String rsKey = 'rs_data';
  static String ethKey = 'eth_data';
  static String dasKey = 'das_key';
  static String operationKey = 'operation_key';

  static SizedBox getVerticalMargin(double size) {
    return SizedBox(
      height: size,
    );
  }

  static dynamic getValueOfKey(dynamic data, String key) {
    for (var i = 0; i < data.length; i++) {
      if (data[i]['key'] == key) {
        return data[i]['value'];
      }
    }
    return '';
  }

  static String hexToAscii(String hexString) => List.generate(
        hexString.length ~/ 2,
        (i) => String.fromCharCode(
            int.parse(hexString.substring(i * 2, (i * 2) + 2), radix: 16)),
      ).join();

  static String computeCRC(String data) {
    const int polynomial = 0xA001; // the polynomial used for the Modbus CRC
    int crc = 0xFFFF; // initial value for the Modbus CRC
    List<int> dataBytes =
        data.codeUnits; // convert the ASCII string to a list of bytes
    for (int i = 0; i < dataBytes.length; i++) {
      crc ^= dataBytes[i];
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ polynomial;
        } else {
          crc = crc >> 1;
        }
      }
    }
    String crcstring = crc.toRadixString(16);
    crcstring = crcstring.substring(2) + crcstring.substring(0, 2);
    return Helper.hexToAscii(crcstring);
  }

  static SizedBox getHorizontalMargin(double size) {
    return SizedBox(
      width: size,
    );
  }

  static String intToHexString(int x) {
    return x.toRadixString(16).padLeft(4, '0');
  }

  static Uint8List convertStringToUint8List(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);

    return unit8List;
  }

  static String convertUint8ListToString(Uint8List uint8list) {
    return String.fromCharCodes(uint8list);
  }

  static Future<void> showError(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static showToast(BuildContext context, String message,
      {bool isError = false}) {
    try {
      var fToast = FToast();
      fToast.init(context);

      Widget toast = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: isError ? Colors.redAccent : Colors.greenAccent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isError ? Icons.cancel : Icons.check),
            const SizedBox(
              width: 12.0,
            ),
            Text(message),
          ],
        ),
      );
      fToast.showToast(
        child: toast,
        gravity: ToastGravity.BOTTOM,
        toastDuration: const Duration(seconds: 2),
      );
    } catch (e) {}

    // Custom Toast Position
    // fToast.showToast(
    //   child: toast,
    //   toastDuration: Duration(seconds: 2),
    //   positionedToastBuilder: (context, child) {
    //     return Positioned(
    //       child: child,
    //       top: 16.0,
    //       left: 16.0,
    //     );
    //   },
    // );
  }

  static Uint8List getVoltagReadCommand() {
    var x = '010310960002';
    var crc = Helper.computeCRC(x);
    var data = ':$x$crc\r\n';
    print(data);
    return Helper.convertStringToUint8List(data);
  }

  static Uint8List getCurrentReadCommand() {
    var x = '01031097000254';
    var crc = Helper.computeCRC(x);
    var data = ':$x$crc\r\n';
    print(data);
    return Helper.convertStringToUint8List(data);
  }

  static Uint8List getVoltagWriteCommand(double voltage) {
    var y = '';
    if (voltage * 10 > 20000) {
      voltage = 20000;
      y = voltage.round().toRadixString(16);
    } else {
      y = (voltage * 10).round().toRadixString(16);
    }
    var x = '0106109C$y';
    var crc = Helper.computeCRC(x);
    var data = ':$x$crc\r\n';
    print(data);
    return Helper.convertStringToUint8List(data);
  }

  static Uint8List getCurrentWriteCommand(double current) {
    var y = '';
    if (current * 10 > 60) {
      current = 60;
      y = current.round().toRadixString(16);
    } else {
      y = (current * 10).round().toRadixString(16);
    }
    var x = '0106109C$y';
    var crc = Helper.computeCRC(x);
    var data = ':$x$crc\r\n';
    print(data);
    return Helper.convertStringToUint8List(data);
  }

  static Uint8List getHvOnOffCommand() {
    return Helper.convertStringToUint8List(':0106109A000151\r\n');
  }

  static dynamic readValueFromHex(String hex, bool isCurrent,
      {bool returnInt = false}) {
    var postFix = isCurrent ? ' A' : ' V';
    try {
      List<String> x = hex.split('');
      var valueHex = '';
      for (var i = 8; i < 12; i++) {
        valueHex += x[i];
      }
      var result = int.parse(valueHex, radix: 16) / 10;
      return returnInt ? result : '$result$postFix';
    } catch (e) {
      return returnInt ? 0 : '0.0$postFix';
    }
  }

  static String getRandomString(int length) {
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }
}
