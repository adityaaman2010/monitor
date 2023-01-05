import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

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
  static SizedBox getVerticalMargin(double size) {
    return SizedBox(
      height: size,
    );
  }

  static SizedBox getHorizontalMargin(double size) {
    return SizedBox(
      width: size,
    );
  }
}
