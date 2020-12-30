import 'package:flutter/material.dart';

class Command {
  String op;
  String args;

  Command({@required this.op, this.args = ''});

  @override
  String toString() {
    String cmd = '{';
    cmd = cmd + '"op":"' + this.op + '"';
    if (args != '') {
      cmd = cmd + ',"args": ["' + this.args + '"]';
    }
    cmd = cmd + '}';
    return cmd;
  }
}
