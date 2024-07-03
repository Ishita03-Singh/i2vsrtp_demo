import 'package:flutter/material.dart';

class Changables with ChangeNotifier {
  ValueNotifier<Widget> videoContainerWidget =
      ValueNotifier<Widget>(Container());
}

Changables changables = new Changables();
