import 'dart:async';
import 'package:bybit/logger.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ByBitWebSocket {
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
  final int timeout;

  /// For easy debugging
  LoggerSingleton log;

  /// Connect to the server with a WebSocket. A ping shall be send every [pingLooTimer] seconds
  /// in order to keep the connection alive.
  ByBitWebSocket(
      {this.url = 'wss://stream.bybit.com/realtime',
      this.key = '',
      this.password = '',
      this.timeout = 1000,
      int pingLoopTimer = 30}) {
    log = LoggerSingleton();
    if (pingLoopTimer > 0) {
      Timer.periodic(Duration(seconds: pingLoopTimer), (timer) {
        ping();
      });
    }
  }

  /// Open a WebSocket connection to the Bybit API
  void connect() {
    int timestamp = DateTime.now().millisecondsSinceEpoch + this.timeout;
    String signature = sign(secret: this.password, timestamp: timestamp);
    String param =
        'api_key=' + this.key + '&expires=' + timestamp.toString() + '&signature=' + signature;
    log.i('Open WebSocket on: ' + this.url + '?' + param);
    this.websocket = IOWebSocketChannel.connect(this.url + '?' + param);
  }

  /// Disconnect the WebSocket
  void disconnect() {
    // todo
  }

  /// Generate a signature needed for the WebSocket authentication as defined here:
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-websocketauthentication
  String sign({@required String secret, @required int timestamp}) {
    List<int> msg = utf8.encode('GET/realtime' + timestamp.toString());
    List<int> key = utf8.encode(secret);
    Hmac hmac = new Hmac(sha256, key);
    return hmac.convert(msg).toString();
  }

  /// Send a command ([op]) and optional arguments to Bybit over the websocket
  void request({@required String op, List<String> args}) {
    String cmd = '{"op":"$op"';
    if (args != null && args != []) {
      cmd = cmd + ',"args": ["' + args.join('.') + '"]';
    }
    cmd += '}';
    log.d("send command " + cmd);
    this.websocket.sink.add(cmd);
  }

  /// send a subscribtion request to a specific [topic] to Bybit
  void subscribeTo({@required String topic, String symbol = '', String filter = ''}) {
    List<String> args = [];
    args.add(topic);
    if (filter != null && filter != '') args.add(filter);
    if (symbol != null && symbol != '') args.add(symbol);
    request(op: 'subscribe', args: args);
  }

  /// Send ping command to Bybit to check connection
  void ping() {
    request(op: 'ping');
  }
}
