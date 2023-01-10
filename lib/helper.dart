import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modbus/modbus.dart' as modbus;

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
    return lrc.toRadixString(16).toUpperCase();
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

  static String getHexForOutput(double ip, int limit) {
    var y = '';
    if (ip * 10 > limit) {
      ip = limit.ceilToDouble();
      y = ip.round().toRadixString(16).toUpperCase();
    } else {
      y = (ip * 10).round().toRadixString(16).toUpperCase();
    }
    var pads = 4 - (y.length);
    for (var i = 0; i < pads; i++) {
      y = '0$y';
    }
    return y;
  }

  static Uint8List getVoltagWriteCommand(double voltage) {
    var y = Helper.getHexForOutput(voltage, 20000);
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
    return Helper.convertStringToUint8List(':0110109D0002040106200015\r\n');
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
      for (var i = 9; i < 13; i++) {
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
    var client = modbus.createTcpClient(
      ip,
      port: port,
      mode: modbus.ModbusMode.rtu,
      unitId: 1,
    );
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
}
