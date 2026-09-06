import 'package:flutter/material.dart';

class Nav {
  static Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget screen,
  ) {
    return Navigator.pushReplacement<T, TO>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }
}
