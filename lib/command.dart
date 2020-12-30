import 'package:flutter/material.dart';

/// Helper to send commands to the server over WebSocket
class Command {
  /// The operation aka command to send. mostly "subscribe" or "ping"
  String op;

  /// The optional arguments that goes with the command
  String args;

  Command({@required this.op, this.args = ''});

  /// Convert the Command to a valid string that can be send over the WebSocket
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
