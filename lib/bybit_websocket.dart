import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:bybit/logger.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ByBitWebSocket {
  /// WebSocket that is used for the bybit communication
  WebSocketChannel websocket;

  /// Url to use for the WebSocket connection
  /// See https://bybit-exchange.github.io/docs/inverse/#t-websocket
  /// For a list of valid urls
  final String url;

  /// Your bybit api-key
  final String key;

  /// Your api-key password
  final String password;

  /// Timeout that triggers a reconnection.
  Duration timeout;

  /// Timer that triggers the timeout exception
  RestartableTimer timeoutTimer;

  /// Ping period in seconds
  final int pingPeriod;

  /// For easy debugging
  LoggerSingleton log;

  /// Time that will ping the websocket server every X seconds.
  Timer pingTimer;

  /// Sream controller used to remap the websocket stream output to json data.
  StreamController<Map<String, dynamic>> controller;

  /// Transformer that actually transform JSON string to Map
  StreamTransformer<dynamic, Map<String, dynamic>> transformer;

  /// Used to know if we are in a timeout state
  bool isTimeout = false;

  /// Connect to the server with a WebSocket. A ping shall be send every
  /// [pingLooTimer] seconds in order to keep the connection alive.
  ByBitWebSocket(
      {this.url = 'wss://stream.bybit.com/realtime',
      this.key = '',
      this.password = '',
      this.timeout,
      this.pingPeriod = 30}) {
    log = LoggerSingleton();
  }

  /// Open a WebSocket connection to the Bybit API
  void connect() {
    log.d('ByBitWebSocket.connect()');
    isTimeout = false;

    timeoutTimer = RestartableTimer(timeout, () {
      log.d('ByBitWebSocket timeoutTimer expired.');
      isTimeout = true;
      disconnect();
    });

    transformer = StreamTransformer<dynamic, Map<String, dynamic>>.fromHandlers(
      handleData: (data, sink) {
        timeoutTimer.reset();
        sink.add(jsonDecode(data.toString()) as Map<String, dynamic>);
      },
      handleDone: (sink) {
        if (isTimeout) {
          log.d('WebSocket closed');
          var e = <String, dynamic>{};
          e['error'] = 'ws_timeout';
          sink.add(e);
        }
      },
      handleError: (error, stackTrace, sink) {
        log.e('ByBitWebSocket transformer error: ' + error.toString());
      },
    );
    controller = StreamController<Map<String, dynamic>>();

    // +1000 is the timeout to avoir repeat attacks
    var timestamp = DateTime.now().millisecondsSinceEpoch + 1000;
    var signature = sign(secret: password, timestamp: timestamp);
    var param = 'api_key=' +
        key +
        '&expires=' +
        timestamp.toString() +
        '&signature=' +
        signature;
    log.i('Open WebSocket on: ' + url + '?' + param);

    websocket = WebSocketChannel.connect(Uri.parse(url + '?' + param));
    controller.addStream(
        websocket.stream.map((value) => value).transform(transformer));
    timeoutTimer.reset();

    if (pingPeriod > 0) {
      ping(); // Start ping
      pingTimer = Timer.periodic(Duration(seconds: pingPeriod), (timer) {
        ping();
      });
    }
  }

  /// Disconnect the WebSocket
  void disconnect() {
    log.d('ByBitWebSocket.disconnect()');
    if (pingTimer != null) {
      pingTimer.cancel();
    }
    if (websocket != null) {
      websocket.sink.close(status.goingAway);
    } else {
      log.e('was already disconnected');
    }
    pingTimer = null;
    websocket = null;
    controller = null;
    transformer = null;
    timeoutTimer = null;
  }

  /// Generate a signature needed for the WebSocket authentication as defined here:
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-websocketauthentication
  String sign({@required String secret, @required int timestamp}) {
    var msg = utf8.encode('GET/realtime' + timestamp.toString());
    var key = utf8.encode(secret);
    var hmac = Hmac(sha256, key);
    return hmac.convert(msg).toString();
  }

  /// Send a command ([op]) and optional arguments to Bybit over the websocket
  void request({@required String op, List<String> args}) {
    var cmd = '{"op":"$op"';
    if (args != null && args != []) {
      cmd = cmd + ',"args": ["' + args.join('.') + '"]';
    }
    cmd += '}';
    log.d('send command ' + cmd);
    websocket.sink.add(cmd);
  }

  /// send a subscribtion request to a specific [topic] to Bybit
  void subscribeTo(
      {@required String topic, String symbol = '', String filter = ''}) {
    var args = <String>[];
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
