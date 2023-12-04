// import 'package:flutter_mb/services/ntp_time_offset.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

int get timestamp => Date().timestamp();
class Date {
  String toYYMMDD() {
    final now = DateTime.now();
    // final offset = NTPTimeOffset.instance.offsetInMilliseconds;
    // final correctTime = now.add(Duration(milliseconds: offset));
    return DateFormat('yyyy-MM-dd').format(now.toUtc()).toString();
  }

  String toYYMMDDhhMMss() {
    final now = DateTime.now();
    // final offset = NTPTimeOffset.instance.offsetInMilliseconds;
    // final correctTime = now.add(Duration(milliseconds: offset));
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now.toUtc()).toString();
  }

    String toYYMMDDhhMMssMS() {
    final now = DateTime.now();
    // final offset = NTPTimeOffset.instance.offsetInMilliseconds;
    // final correctTime = now.add(Duration(milliseconds: offset));
    return DateFormat('yyyy-MM-dd HH:mm:sss').format(now.toUtc()).toString();
  }

  int timestamp() {
    final now = DateTime.now();
    // final offset = NTPTimeOffset.instance.offsetInMilliseconds;
    // final correctTime = now.add(Duration(milliseconds: offset));
    return now.millisecondsSinceEpoch ~/ 1000;
  }
}

  bool isBigDeviceScreen(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight > 1000);
  }