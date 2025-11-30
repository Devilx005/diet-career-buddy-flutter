import 'package:flutter/material.dart';

void downloadApk(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('APK download is available on the web version only.'),
    ),
  );
}
