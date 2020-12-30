import 'package:flutter/material.dart';

/// Defines a topic that can be subscribed to over a WebSocket
class Topic {
  /// [name] of the topic: a complete list of all public and private topics can
  /// be found at https://bybit-exchange.github.io/docs/inverse/#t-publictopics
  final String name;

  /// The symbol of the exchange, as defined at
  /// https://bybit-exchange.github.io/docs/inverse/#symbol-symbol
  final String symbol;

  /// A topic-specific filter
  final String filter;

  Topic({@required this.name, this.symbol = '', this.filter = ''});

  /// Convert the [Topic] to a valid string that can be send over a WebSocket
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
