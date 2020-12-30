import 'package:flutter/material.dart';

class Topic {
  final String name;
  final String symbol;
  final String filter;

  Topic({@required this.name, this.symbol = '', this.filter = ''});

  @override
  String toString() {
    String value = this.name;
    if (this.filter != '') {
      value = value + '.' + this.filter;
    }
    if (this.symbol != '') {
      value = value + '.' + this.symbol;
    }
    return value;
  }
}
