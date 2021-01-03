import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:bybit/logger.dart';
import 'package:http/http.dart' as http;

class ByBitRest {
  /// HTTP client that is used for the bybit communication over the REST API
  http.Client client;

  /// Url to use for the REST requests. List of all entpoints at:
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-authentication
  final String url;

  /// Your bybit api-key
  final String key;

  /// Your api-key password
  final String password;

  /// Timeout for the requests used by bybit to prevent replay attacks.
  final int timeout;

  /// For easy debugging
  LoggerSingleton log;

  /// Constructor yolo swag
  ByBitRest(
      {this.url = 'https://api.bybit.com',
      this.key = '',
      this.password = '',
      this.timeout = 1000}) {
    log = LoggerSingleton();
  }

  /// Connect a HTTP client to the server
  bool connect() {
    if (client != null) client.close();
    client = http.Client();
    return true;
  }

  /// Disconnect the HTTP client
  void disconnect() {
    client.close();
  }

  /// Generate a signature needed for the REST authentication as defined here:
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-constructingtherequest
  String sign({@required String secret, @required SortedMap query}) {
    var queryString = '';
    query.forEach((key, value) {
      queryString += '$key=$value&';
    });
    // remove last '&' from string
    queryString = queryString.substring(0, queryString.length - 1);
    var msg = utf8.encode(queryString);
    var key = utf8.encode(secret);
    var hmac = Hmac(sha256, key);
    return hmac.convert(msg).toString();
  }

  /// Send command to Bybit
  Future<dynamic> request(
      {@required String path,
      Map<String, dynamic> parameters,
      bool withAuthentication = false,
      String type = 'POST'}) async {
    var map = SortedMap(Ordering.byKey());

    if (parameters != null) {
      /// Keep the parameters sorted alphabetically for valid requests
      parameters.forEach((id, value) {
        log.d('Parameter ' + id + ': ' + value.toString());
        map[id] = value;
      });
    }

    var params = '';
    if (withAuthentication) {
      map['api_key'] = key;
      var timestamp = DateTime.now().millisecondsSinceEpoch;
      map['timestamp'] = timestamp;
      map['recv_window'] = timeout;
      var signature = sign(secret: password, query: map);
      map['sign'] = signature;
    }

    http.Response response;
    var header = <String, String>{};
    header['Content-Type'] = 'application/json; charset=utf-8';
    if (type == 'POST') {
      var finalUrl = url + path;
      var query = '{';
      map.forEach((key, value) {
        query += '"$key":';
        if (value is String) {
          query += '"$value"';
        } else if (value is double) {
          query = query + '"' + value.toString() + '"';
        } else {
          query += value.toString();
        }
        query += ',';
      });
      // replace last ',' in query string
      if (map.isNotEmpty) query = query.substring(0, query.length - 1);
      query += '}';
      log.d('POST ' + finalUrl + ' ' + header.toString() + ' ' + query);
      response = await http.post(finalUrl, headers: header, body: query);
      if (response.statusCode != 200) {
        log.e('HTTP response status code: ' + response.statusCode.toString());
      }
      return jsonDecode(response.body);
    } else if (type == 'GET') {
      header['Content-Type'] = 'application/json; charset=utf-8';
      if (map.isNotEmpty) params = '?';
      map.forEach((id, value) {
        params = params + id.toString() + '=' + value.toString() + '&';
      });
      // remove last '&' from string
      if (map.isNotEmpty) params = params.substring(0, params.length - 1);
      var finalUrl = url + path + params;
      log.d('GET ' + finalUrl);
      response = await http.get(finalUrl, headers: header);
      if (response.statusCode != 200) {
        log.e('HTTP response status code: ' + response.statusCode.toString());
      }
      return jsonDecode(response.body);
    } else {
      log.e('Request type ' + type + ' is not supported');
      return jsonDecode('');
    }
  }
}
