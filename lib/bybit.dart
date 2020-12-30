library bybit;

import 'dart:convert';
import 'package:bybit/command.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';
import 'package:bybit/topic.dart';

class ByBit {
  /// WebSocket that is used for the bybit communication
  IOWebSocketChannel websocket;

  /// Url to use for the WebSocket connection
  final String url;

  /// Your bybit api-key
  final String apiKey;

  /// Your api-key password
  final String secret;

  /// Timeout in milliseconds
  int timeout;

  /// For debugging purposes
  Logger logger;

  ByBit(
      {this.url = 'wss://stream.bybit.com/realtime',
      this.apiKey = '',
      this.secret = '',
      this.timeout = 1000,
      Level logLevel = Level.debug}) {
    logger = Logger(printer: SimplePrinter(colors: true), level: logLevel);
  }

  String _getSignature(String secret, int timestamp) {
    List<int> msg = utf8.encode('GET/realtime' + timestamp.toString());
    List<int> key = utf8.encode(secret);
    Hmac hmac = new Hmac(sha256, key);
    return hmac.convert(msg).toString();
  }

  void connect() {
    int timestamp = DateTime.now().millisecondsSinceEpoch + this.timeout;
    String signature = _getSignature(this.secret, timestamp);
    String param = 'api_key=' +
        this.apiKey +
        '&expires=' +
        timestamp.toString() +
        '&signature=' +
        signature;
    logger.i('Open socket: ' + this.url + '?' + param);
    this.websocket = IOWebSocketChannel.connect(this.url + '?' + param);
  }

  void _sendCommand(Command cmd) {
    logger.d("send command " + cmd.toString());
    this.websocket.sink.add(cmd.toString());
  }

  void subscribeTo(Topic topic) {
    _sendCommand(Command(op: 'subscribe', args: topic.toString()));
  }

  void ping() {
    _sendCommand(Command(op: 'ping'));
  }

  void subscribeToKlines({@required String symbol, @required String interval}) {
    subscribeTo(Topic(name: 'klineV2', symbol: symbol, filter: interval));
  }

  void subscribeToPosition() {
    subscribeTo(Topic(name: 'position'));
  }

  void subscribeToExecution() {
    subscribeTo(Topic(name: 'execution'));
  }

  void subscribeToOrder() {
    subscribeTo(Topic(name: 'order'));
  }

  void subscribeToStopOrder() {
    subscribeTo(Topic(name: 'stop_order'));
  }
}
