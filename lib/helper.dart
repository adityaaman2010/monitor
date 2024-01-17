import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modbus/modbus.dart' as modbus;


var currentLookup = {
  0: 0,
  0.1: 240,
  0.2: 510,
  0.3: 731,
  0.4: 846,
  0.5: 956,
  0.6: 1016,
  0.7: 1120,
  0.8: 1430,
  0.9: 2621,
  1.0: 3670,
  1.1: 4522,
  1.2: 5505,
  1.3: 6619,
  1.4: 7700,
  1.5: 8841,
  1.6: 9988,
  1.7: 11062,
  1.8: 12209,
  1.9: 13304,
  2.0: 14418,
  2.1: 15532,
  2.2: 16711,
  2.3: 17760,
  2.4: 20054,
  2.5: 21168,
  2.6: 22282,
  2.7: 23448,
  2.8: 24510,
  2.9: 25624,
  3.0: 26738,
  3.1: 29032,
  3.2: 30146,
  3.3: 31195,
  3.4: 32309,
  3.5: 33488,
  3.6: 35651,
  3.7: 36765,
  3.8: 37879,
  3.9: 38993,
  4.0: 40107,
  4.1: 42336,
  4.2: 43450,
  4.3: 44564,
  4.4: 45678,
  4.5: 46792,
  4.6: 47906,
  4.7: 50134,
  4.8: 51183,
  4.9: 52297,
  5.0: 53411,
  5.1: 54460,
  5.2: 55574,
  5.3: 57802,
  5.4: 58916,
  5.5: 60030,
  5.6: 61079,
  5.7: 62193,
  5.8: 63634,
  5.9: 65011,
  6.0: 65535,
};

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
  static String useEthKey = 'use_eth';
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

  static String computeLRC(String string_data) {
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
    return lrc.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  static Uint8List getVoltagReadCommand() {
    var x = '010310960001';
    var lrc = Helper.computeLRC(x);
    var data = ':$x$lrc\r\n';
    return Helper.convertStringToUint8List(data);
  }

  static Uint8List getCurrentReadCommand() {
    var x = '010310970001';
    var crc = Helper.computeLRC(x);
    var data = ':$x$crc\r\n';
    return Helper.convertStringToUint8List(data);
  }

  static String getHexForVoltageOutPut(double ip) {
    int multiplier = 0;
    if (ip > 0 && ip <= 20) {
      multiplier = (20000 / 20).floor();
    } else if (ip > 20 && ip <= 200) {
      multiplier = (20000 / 200).floor();
    } else {
      multiplier = (20000 / 2000).floor();
    }
    double x = ip * multiplier;
    var y = x.round().toRadixString(16).toUpperCase();
    var pads = 4 - (y.length);
    for (var i = 0; i < pads; i++) {
      y = '0$y';
    }
    return y;
  }

  static String getHexForOutput(double ip, int limit) {
    var y = '';
    if (ip * 10 > limit) {
      ip = limit.ceilToDouble();
      y = (ip * 10).round().toRadixString(16).toUpperCase();
    } else {
      y = (ip * 10).round().toRadixString(16).toUpperCase();
    }
    var pads = 4 - (y.length);
    for (var i = 0; i < pads; i++) {
      y = '0$y';
    }
    return y;
  }

  static String getHexFromInt(int inputValue){
    var y = '';
    y = inputValue.toRadixString(16).toUpperCase();
    var pads = 4 - (y.length);
    for (var i = 0; i < pads; i++) {
      y = '0$y';
    }
    return y;
  }



  static Uint8List getVoltagWriteCommand(double voltage) {
    var y = Helper.getHexForVoltageOutPut(voltage);
    var x = '0106109B$y'.toUpperCase();
    var crc = Helper.computeLRC(x);
    var data = ':$x$crc\r\n';
    print(data);
    return Helper.convertStringToUint8List(data);
  }

  static Uint8List getCurrentWriteCommand(double current) {
    var y = Helper.getHexForOutput(current, 60);
    var x = '0106109C$y'.toUpperCase();
    var crc = Helper.computeLRC(x);
    var data = ':$x$crc\r\n';
    print(data);
    return Helper.convertStringToUint8List(data);
  }

  static Uint8List getHvPassword() {
    var x = '0106109D07D6';
    var crc = Helper.computeLRC(x);
    return Helper.convertStringToUint8List(':$x$crc\r\n');
  }

  static Uint8List getHvOnOffCommand(bool on) {
    var x = on ? '0106109A0001' : '0106109A0000';
    var crc = Helper.computeLRC(x);
    return Helper.convertStringToUint8List(':$x$crc\r\n');
  }

  static dynamic readValueFromHex(String hex, bool isCurrent,
      {bool returnInt = false}) {
    var postFix = isCurrent ? ' A' : ' V';
    try {
      List<String> x = hex.split('');
      var valueHex = '';
      for (var i = 7; i < 11; i++) {
        valueHex += x[i];
      }
      var result = int.parse(valueHex, radix: 16) / 10;
      print('reading packet helper - 246 ==> $hex id equal to $result');
      return returnInt ? result : '$result $postFix';
    } catch (e) {
      return returnInt ? 0 : '0.0 $postFix';
    }
  }

  static String getRandomString(int length) {
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  static int getRegister({bool isVoltage = true, bool isRead = false}) {
    if (isVoltage) {
      return isRead ? 4246 : 4251;
    } else {
      return isRead ? 4247 : 4252;
    }
  }

  static int getHvRegister({bool isPassword = false}) {
    return isPassword ? 4253 : 4250;
  }

  static modbus.ModbusClient getEthClient(dynamic ethData) {
    var ip = ethData[0]['value'];
    var port = int.parse(ethData[1]['value']);
    var client = modbus.createTcpClient(ip,
        port: port,
        mode: modbus.ModbusMode.rtu,
        unitId: 1,
        timeout: const Duration(seconds: 2));
    return client;
  }

  static void initethernet(String ip, int port) async {
    var client = modbus.createTcpClient(
      ip,
      port: port,
      mode: modbus.ModbusMode.rtu,
      unitId: 1,
    );

    try {
      await client.connect();

      var slaveIdResponse = await client.reportSlaveId();

      StringBuffer sb = StringBuffer();
      slaveIdResponse.forEach((f) {
        sb.write(f.toRadixString(16).padLeft(2, '0'));
        sb.write(" ");
      });
      print("Slave ID: " + sb.toString());
      // await client.writeSingleRegister(4245, 1234);
      var registers = await client.readHoldingRegisters(4245, 1);
      for (int i = 0; i < registers.length; i++) {
        print("REG_I[${i}]: " + registers.elementAt(i).toString());
      }
    } finally {
      client.close();
    }
  }

  static String getVoltageRange() {
    return '0-2000V';
  }

  static String getCurrentRange() {
    return '0-6A';
  }

  static List<int> getPlcInputRange({bool isCurrent = false}) {
    List<int> result = [];
    if (isCurrent) {
      result.add(0);
      result.add(6);
    } else {
      result.add(0);
      result.add(2000);
    }
    return result;
  }
}
