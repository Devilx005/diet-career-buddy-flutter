// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';

void downloadApk(BuildContext context) {
  html.window.open('/assets/Pathify AI.apk', '_blank');
}
