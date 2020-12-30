library bybit;

import 'dart:convert';
import 'package:bybit/command.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';
import 'package:bybit/topic.dart';

/// That class opens a WebSocket to communicate with the bybit API
/// You can subscribes to several topics over that WebSocket
/// To see a complete list of all endpoints, see
/// https://bybit-exchange.github.io/docs/inverse/#t-websocket
class ByBit {
  /// WebSocket that is used for the bybit communication
  IOWebSocketChannel websocket;

  /// Url to use for the WebSocket connection
  /// See https://bybit-exchange.github.io/docs/inverse/#t-websocket
  /// For a list of valid urls
  final String url;

  /// Your bybit api-key
  final String key;

  /// Your api-key password
  final String password;

  /// Timeout for the requests used by bybit to prevent replay attacks.
  int timeout;

  /// For debugging purposes
  Logger logger;

  /// The constructor use default parameters without api-key
  /// If you want to use all endpoints, you must provite a valid
  /// [key] and [password]. Go to https://www.bybit.com/app/user/api-management
  /// To generate your key
  ByBit(
      {this.url = 'wss://stream.bybit.com/realtime',
      this.key = '',
      this.password = '',
      this.timeout = 1000,
      Level logLevel = Level.warning}) {
    logger = Logger(printer: SimplePrinter(colors: true), level: logLevel);
  }

  /// Generate a signature needed for the WebSocket authentication
  String _getSignature(String secret, int timestamp) {
    List<int> msg = utf8.encode('GET/realtime' + timestamp.toString());
    List<int> key = utf8.encode(secret);
    Hmac hmac = new Hmac(sha256, key);
    return hmac.convert(msg).toString();
  }

  /// Open a WebSocket connection to the Bybit API
  void connect() {
    int timestamp = DateTime.now().millisecondsSinceEpoch + this.timeout;
    String signature = _getSignature(this.password, timestamp);
    String param = 'api_key=' +
        this.key +
        '&expires=' +
        timestamp.toString() +
        '&signature=' +
        signature;
    logger.i('Open socket: ' + this.url + '?' + param);
    this.websocket = IOWebSocketChannel.connect(this.url + '?' + param);
  }

  /// Send command to Bybit
  void _sendCommand(Command cmd) {
    logger.d("send command " + cmd.toString());
    this.websocket.sink.add(cmd.toString());
  }

  /// Send a subscription [Command] to Bybit with a given [topic]
  void subscribeTo(Topic topic) {
    _sendCommand(Command(op: 'subscribe', args: topic.toString()));
  }

  /// Send ping command to Bybit to check connection
  void ping() {
    _sendCommand(Command(op: 'ping'));
  }

  /// Subscribe to the KLines channel. A list of valid [interval] values string
  /// is at: https://bybit-exchange.github.io/docs/inverse/#t-websocketklinev2
  void subscribeToKlines({@required String symbol, @required String interval}) {
    subscribeTo(Topic(name: 'klineV2', symbol: symbol, filter: interval));
  }

  /// Subscribe to the position channel. You need to have a valid api-key
  /// in order to receive a valid response from the server
  void subscribeToPosition() {
    subscribeTo(Topic(name: 'position'));
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketexecution
  void subscribeToExecution() {
    subscribeTo(Topic(name: 'execution'));
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketorder
  void subscribeToOrder() {
    subscribeTo(Topic(name: 'order'));
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketstoporder
  void subscribeToStopOrder() {
    subscribeTo(Topic(name: 'stop_order'));
  }
}
