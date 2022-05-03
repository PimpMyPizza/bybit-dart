import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:bybit/logger.dart';
import 'package:http/http.dart' as http;
import 'package:async/async.dart' show StreamGroup;

class ByBitRest {
  /// HTTP client that is used for the bybit communication over the REST API
  /// todo: not used atm but I should!
  http.Client? client;

  /// Url to use for the REST requests. List of all entpoints at:
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-authentication
  final String url;

  /// Your bybit api-key
  final String key;

  /// Your api-key password
  final String password;

  /// Timeout value
  Duration? timeout;

  /// Receive window in milliseconds. See
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-authentication
  int receiveWindow;

  /// For easy debugging
  late LoggerSingleton log;

  /// Group all periodic REST calls stream
  StreamGroup<Map<String, dynamic>?>? streamGroup;

  /// Contains a list of periodic REST calls streams. These streams are
  /// merged together into one stream when the connect() function is called
  var streamList = <Stream<Map<String, dynamic>>>[];

  /// Constructor of the REST API communication. The [receiveWindow] must be
  /// given in milliseconds and prevents replay attacks. See
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-authentication
  ByBitRest(
      {this.url = 'https://api.bybit.com',
      this.key = '',
      this.password = '',
      this.timeout,
      this.receiveWindow = 1000}) {
    log = LoggerSingleton();
  }

  /// Connect a HTTP client to the server
  bool connect() {
    if (client != null) client!.close();
    client = http.Client();
    streamGroup = StreamGroup();
    return true;
  }

  /// Disconnect the HTTP client
  void disconnect() {
    client!.close();
    streamGroup!.close();
    client = null;
    streamGroup = null;
  }

  /// Generate a signature needed for the REST authentication as defined here:
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-constructingtherequest
  String sign({required String secret, required SortedMap query}) {
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
  Future<Map<String, dynamic>?> request(
      {required String path,
      Map<String, dynamic>? parameters,
      bool withAuthentication = false,
      String type = 'POST'}) async {
    var map = SortedMap(Ordering.byKey());

    if (parameters != null) {
      /// Keep the parameters sorted alphabetically for valid requests
      parameters.forEach((id, value) {
        log.d('ByBitRest.Parameter ' + id + ': ' + value.toString());
        map[id] = value;
      });
    }

    var params = '';
    if (withAuthentication) {
      map['api_key'] = key;
      var timestamp = DateTime.now().millisecondsSinceEpoch;
      map['timestamp'] = timestamp;
      map['recv_window'] = receiveWindow;
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
      log.d(
          'ByBitRest.POST ' + finalUrl + ' ' + header.toString() + ' ' + query);
      response =
          await http.post(Uri.parse(finalUrl), headers: header, body: query);
      if (response.statusCode != 200) {
        log.e('HTTP response status code: ' + response.statusCode.toString());
      }
      return jsonDecode(response.body) as Map<String, dynamic>?;
    } else if (type == 'GET') {
      header['Content-Type'] = 'application/json; charset=utf-8';
      if (map.isNotEmpty) params = '?';
      map.forEach((id, value) {
        params = params + id.toString() + '=' + value.toString() + '&';
      });
      // remove last '&' from string
      if (map.isNotEmpty) params = params.substring(0, params.length - 1);
      var finalUrl = url + path + params;
      log.d('ByBitRest.GET ' + finalUrl);
      response = await http.get(Uri.parse(finalUrl), headers: header);
      if (response.statusCode != 200) {
        log.e('HTTP response status code: ' + response.statusCode.toString());
      }
      return jsonDecode(response.body) as Map<String, dynamic>?;
    } else {
      log.e('Request type ' + type + ' is not supported');
      return jsonDecode('') as Map<String, dynamic>?;
    }
  }

  /// Get the orderbook.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-orderbook
  Future<Map<String, dynamic>?> getOrderBook({required String symbol}) async {
    log.d('ByBitRest.getOrderBook');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return await request(
        path: '/v2/public/orderBook/L2', type: 'GET', parameters: parameters);
  }

  /// Add a periodic call to the order book REST API.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-orderbook
  void getOrderBookPeriodic(
      {required String symbol, required Duration period}) {
    log.d('ByBitRest.getOrderBookPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getOrderBook(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Get kline. https://bybit-exchange.github.io/docs/inverse/?console#t-querykline
  Future<Map<String, dynamic>?> getKLine(
      {required String symbol,
      required String interval,
      required int from,
      int limit = -1}) async {
    log.d('ByBitRest.getKLine $symbol');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['interval'] = interval;
    parameters['from'] = from;
    if (limit > 0) parameters['limit'] = limit;
    return await request(
        path: '/v2/public/kline/list', type: 'GET', parameters: parameters);
  }

  /// Get kline periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querykline
  void getKLinePeriodic(
      {required String symbol,
      required String interval,
      required int from,
      int? limit = -1,
      required Duration period}) {
    log.d('ByBitRest.getKLinePeriodic $symbol');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getKLine(
          symbol: symbol, interval: interval, from: from, limit: limit!);
    }).asyncMap((event) async => await event));
  }

  /// Get the latest information for symbol.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-latestsymbolinfo
  Future<Map<String, dynamic>?> getTickers({String? symbol}) async {
    log.d('ByBitRest.getTickers');
    var parameters = <String, dynamic>{};
    if (symbol != null) parameters['symbol'] = symbol;
    return await request(
        path: '/v2/public/tickers', type: 'GET', parameters: parameters);
  }

  /// Get the latest information for symbols periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-latestsymbolinfo
  void getTickersPeriodic({String? symbol, required Duration period}) {
    log.d('ByBitRest.getTickersPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getTickers(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Get recent trades.
  ///
  /// Returns the last trades from a trade id [from] with a limit of [limit]
  /// trades. The latest [limit] trades will be
  /// returned (default [limit]: 500, max: 1000)
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-publictradingrecords
  Future<Map<String, dynamic>?> getTradingRecords(
      {required String symbol, int? limit}) async {
    log.d('ByBitRest.getTradingRecords');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (limit != null) parameters['limit'] = limit;
    return await request(
        path: '/v2/public/trading-records',
        type: 'GET',
        parameters: parameters);
  }

  /// Get recent trades periodically.
  ///
  /// Returns the last trades from a trade id [from] with a limit of [limit]
  /// trades. If no [from] value is given, the latest [limit] trades will be
  /// returned (default [limit]: 500, max: 1000)
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-publictradingrecords
  void getTradingRecordsPeriodic(
      {required String symbol,
      int? from,
      int? limit,
      required Duration period}) {
    log.d('ByBitRest.getTradingRecordsPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getTradingRecords(symbol: symbol, limit: limit);
    }).asyncMap((event) async => await event));
  }

  /// Get the information for all symbols.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  Future<Map<String, dynamic>?> getSymbolsInfo() async {
    log.d('ByBitRest.getSymbolsInfo');
    return await request(path: '/v2/public/symbols', type: 'GET');
  }

  /// Get the information for all symbols periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  void getSymbolsInfoPeriodic({required Duration period}) {
    log.d('ByBitRest.getSymbolsInfoPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getSymbolsInfo();
    }).asyncMap((event) async => await event));
  }

  /// Query mark price kline (like Query Kline but for mark price).
  ///
  /// https://bybit-exchange.github.io/docs/inverse/#t-markpricekline
  Future<Map<String, dynamic>?> getMarkPriceKLine(
      {required String symbol,
      required String interval,
      required int from,
      int? limit}) async {
    log.d('ByBitRest.getMarkPriceKLine');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['interval'] = interval;
    parameters['from'] = from;
    if (limit != null) parameters['limit'] = limit;
    return await request(
        path: '/v2/public/mark-price-kline',
        type: 'GET',
        parameters: parameters);
  }

  /// Query mark price kline (like Query Kline but for mark price) periodically
  ///
  /// https://bybit-exchange.github.io/docs/inverse/#t-markpricekline
  void getMarkPriceKLinePeriodic(
      {required String symbol,
      required String interval,
      required int from,
      int? limit,
      required Duration period}) {
    log.d('ByBitRest.getMarkPriceKLinePeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getMarkPriceKLine(
          symbol: symbol, interval: interval, from: from, limit: limit);
    }).asyncMap((event) async => await event));
  }

  /// Gets the total amount of unsettled contracts. In other words, the total
  /// number of contracts held in open positions.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<Map<String, dynamic>?> getOpenInterest(
      {required String symbol, required String interval, int? limit}) async {
    log.d('ByBitRest.getOpenInterest');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['period'] = interval;
    if (limit != null) parameters['limit'] = limit;
    return await request(
        path: '/v2/public/open-interest', type: 'GET', parameters: parameters);
  }

  /// Gets the total amount of unsettled contracts periodically.
  /// In other words, get the total number of contracts held in open positions
  /// every [period].
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  void getOpenInterestPeriodic(
      {required String symbol,
      required String interval,
      int? limit,
      required Duration period}) {
    log.d('ByBitRest.getOpenInterestPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getOpenInterest(symbol: symbol, interval: interval, limit: limit);
    }).asyncMap((event) async => await event));
  }

  /// Obtain filled orders worth more than 500,000 USD within the last 24h.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<Map<String, dynamic>?> getLatestBigDeals(
      {required String symbol, int? limit}) async {
    log.d('ByBitRest.getLatestBigDeals');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (limit != null) parameters['limit'] = limit;
    return await request(
        path: '/v2/public/big-deal', type: 'GET', parameters: parameters);
  }

  /// Obtain filled orders worth more than 500,000 USD within the last 24h,
  /// periodically.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  void getLatestBigDealsPeriodic(
      {required String symbol, int? limit, required Duration period}) {
    log.d('ByBitRest.getLatestBigDealsPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getLatestBigDeals(symbol: symbol, limit: limit);
    }).asyncMap((event) async => await event));
  }

  /// Gets the Bybit user accounts' long-short ratio.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<Map<String, dynamic>?> getLongShortRatio(
      {required String symbol, required String interval, int? limit}) async {
    log.d('ByBitRest.getLongShortRatio');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['period'] = interval;
    if (limit != null) parameters['limit'] = limit;
    return await request(
        path: '/v2/public/account-ratio', type: 'GET', parameters: parameters);
  }

  /// Gets the Bybit user accounts' long-short ratio periodically
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  void getLongShortRatioPeriodic(
      {required String symbol,
      required String interval,
      int? limit,
      required Duration period}) {
    log.d('ByBitRest.getLongShortRatioPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getLongShortRatio(
          symbol: symbol, interval: interval, limit: limit);
    }).asyncMap((event) async => await event));
  }

  /// Place active order
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive
  Future<Map<String, dynamic>?> placeActiveOrder({
    required String symbol,
    required String side,
    required String orderType,
    required int quantity,
    required String timeInForce,
    double? price,
    double? takeProfit,
    double? stopLoss,
    bool? reduceOnly,
    bool? closeOnTrigger,
    String? orderLinkId,
    String? tpTriggerBy,
    String? slTriggerBy,
  }) async {
    log.d('ByBitRest.placeActiveOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['side'] = side;
    parameters['order_type'] = orderType;
    parameters['qty'] = quantity;
    parameters['time_in_force'] = timeInForce;
    if (price != null) parameters['price'] = price;
    if (takeProfit != null) parameters['take_profit'] = takeProfit;
    if (stopLoss != null) parameters['stop_loss'] = stopLoss;
    if (reduceOnly != null) parameters['reduce_only'] = reduceOnly;
    if (closeOnTrigger != null) parameters['close_on_trigger'] = closeOnTrigger;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    if (tpTriggerBy != null) parameters['tp_trigger_by'] = tpTriggerBy;
    if (slTriggerBy != null) parameters['sl_trigger_by'] = slTriggerBy;
    return await request(
      path: '/v2/private/order/create',
      type: 'POST',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Place active order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive
  void placeActiveOrderPeriodic(
      {required String symbol,
      required String side,
      required String orderType,
      required int quantity,
      required String timeInForce,
      double? price,
      double? takeProfit,
      double? stopLoss,
      bool? reduceOnly,
      bool? closeOnTrigger,
      String? orderLinkId,
      required Duration period}) {
    log.d('ByBitRest.placeActiveOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return placeActiveOrder(
          symbol: symbol,
          side: side,
          orderType: orderType,
          quantity: quantity,
          timeInForce: timeInForce,
          price: price,
          takeProfit: takeProfit,
          stopLoss: stopLoss,
          reduceOnly: reduceOnly,
          closeOnTrigger: closeOnTrigger,
          orderLinkId: orderLinkId);
    }).asyncMap((event) async => await event));
  }

  /// Get active order
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-getactive
  Future<Map<String, dynamic>?> getActiveOrder(
      {required String symbol,
      String? orderStatus,
      String? direction,
      int? limit,
      String? cursor}) async {
    log.d('ByBitRest.getActiveOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderStatus != null) parameters['order_status'] = orderStatus;
    if (direction != null) parameters['direction'] = direction;
    if (limit != null) parameters['limit'] = limit;
    if (cursor != null) parameters['cursor'] = cursor;
    return await request(
        path: '/v2/private/order/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get active order periodically
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-getactive
  void getActiveOrderPeriodic(
      {required String symbol,
      String? orderStatus,
      String? direction,
      int? limit,
      String? cursor,
      required Duration period}) {
    log.d('ByBitRest.getActiveOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getActiveOrder(
          symbol: symbol,
          orderStatus: orderStatus,
          direction: direction,
          limit: limit,
          cursor: cursor);
    }).asyncMap((event) async => await event));
  }

  /// Cancel active order. Note that either orderId or orderLinkId are required
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelactive
  Future<Map<String, dynamic>?> cancelActiveOrder(
      {required String symbol, String? orderId, String? orderLinkId}) async {
    log.d('ByBitRest.cancelActiveOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return await request(
        path: '/v2/private/order/cancel',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Cancel active order periodically. Note that either orderId or orderLinkId
  /// are required https://bybit-exchange.github.io/docs/inverse/#t-cancelactive
  void cancelActiveOrderPeriodic(
      {required String symbol,
      String? orderId,
      String? orderLinkId,
      required Duration period}) {
    log.d('ByBitRest.cancelActiveOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return cancelActiveOrder(
          symbol: symbol, orderId: orderId, orderLinkId: orderLinkId);
    }).asyncMap((event) async => await event));
  }

  /// Cancel all active orders that are unfilled or partially filled. Fully
  /// filled orders cannot be cancelled.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallactive
  Future<Map<String, dynamic>?> cancelAllActiveOrders(
      {required String symbol}) async {
    log.d('ByBitRest.cancelAllActiveOrders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return await request(
        path: '/v2/private/order/cancelAll',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Cancel all active orders that are unfilled or partially filled periodically.
  /// Fully filled orders cannot be cancelled.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallactive
  void cancelAllActiveOrdersPeriodic(
      {required String symbol, required Duration period}) {
    log.d('ByBitRest.cancelAllActiveOrdersPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return cancelAllActiveOrders(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Replace order can modify/amend your active orders.
  /// https://bybit-exchange.github.io/docs/inverse/#t-replaceactive
  Future<Map<String, dynamic>?> updateActiveOrder({
    required String symbol,
    String? orderId,
    String? orderLinkId,
    int? newOrderQuantity,
    double? newOrderPrice,
    double? takeProfit,
    double? stopLoss,
    String? tpTriggerBy,
    String? slTriggerBy,
  }) async {
    log.d('ByBitRest.updateActiveOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    if (newOrderQuantity != null) {
      parameters['p_r_qty'] = newOrderQuantity.toString();
    }
    if (newOrderPrice != null) {
      parameters['p_r_price'] = newOrderPrice.toString();
    }
    if (takeProfit != null) parameters['take_profit'] = takeProfit;
    if (stopLoss != null) parameters['stop_loss'] = stopLoss;
    if (tpTriggerBy != null) parameters['tp_trigger_by'] = tpTriggerBy;
    if (slTriggerBy != null) parameters['sl_trigger_by'] = slTriggerBy;
    return await request(
      path: '/v2/private/order/replace',
      type: 'POST',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Replace order can modify/amend your active orders periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-replaceactive
  void updateActiveOrderPeriodic(
      {required String symbol,
      String? orderId,
      String? orderLinkId,
      int? newOrderQuantity,
      double? newOrderPrice,
      required Duration period}) {
    log.d('ByBitRest.updateActiveOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return updateActiveOrder(
          symbol: symbol,
          orderId: orderId,
          orderLinkId: orderLinkId,
          newOrderQuantity: newOrderQuantity,
          newOrderPrice: newOrderPrice);
    }).asyncMap((event) async => await event));
  }

  /// Query real-time active order information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-queryactive
  Future<Map<String, dynamic>?> getRealTimeActiveOrder(
      {required String symbol, String? orderId, String? orderLinkId}) async {
    log.d('ByBitRest.getRealTimeActiveOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return await request(
        path: '/v2/private/order',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Query real-time active order information periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-queryactive
  void getRealTimeActiveOrderPeriodic(
      {required String symbol,
      String? orderId,
      String? orderLinkId,
      required Duration period}) {
    log.d('ByBitRest.getRealTimeActiveOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getRealTimeActiveOrder(
          symbol: symbol, orderId: orderId, orderLinkId: orderLinkId);
    }).asyncMap((event) async => await event));
  }

  /// Place a market price conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-placecond
  Future<Map<String, dynamic>?> placeConditionalOrder({
    required String symbol,
    required String side,
    required String orderType,
    required int quantity,
    double? price,
    required double basePrice,
    required double triggerPrice,
    required String timeInForce,
    String? triggerBy,
    bool? closeOnTrigger,
    String? orderLinkId,
    double? takeProfit,
    double? stopLoss,
    String? tpTriggerBy,
    String? slTriggerBy,
  }) async {
    log.d('ByBitRest.placeConditionalOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['side'] = side;
    parameters['order_type'] = orderType;
    parameters['qty'] = quantity.toString();
    parameters['base_price'] = basePrice.toString();
    parameters['stop_px'] = triggerPrice.toString();
    parameters['time_in_force'] = timeInForce;
    parameters['trigger_by'] = triggerBy;
    if (price != null) parameters['price'] = price.toString();
    if (closeOnTrigger != null) parameters['close_on_trigger'] = closeOnTrigger;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    if (takeProfit != null) parameters['take_profit'] = takeProfit;
    if (stopLoss != null) parameters['stop_loss'] = stopLoss;
    if (tpTriggerBy != null) parameters['tp_trigger_by'] = tpTriggerBy;
    if (slTriggerBy != null) parameters['sl_trigger_by'] = slTriggerBy;
    return await request(
        path: '/v2/private/stop-order/create',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Place a market price conditional order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-placecond
  void placeConditionalOrderPeriodic(
      {required String symbol,
      required String side,
      required String orderType,
      required int quantity,
      double? price,
      required double basePrice,
      required double triggerPrice,
      required String timeInForce,
      String? triggerBy,
      bool? closeOnTrigger,
      String? orderLinkId,
      required Duration period}) {
    log.d('ByBitRest.placeConditionalOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return placeConditionalOrder(
          symbol: symbol,
          side: side,
          orderType: orderType,
          quantity: quantity,
          price: price,
          basePrice: basePrice,
          triggerPrice: triggerPrice,
          timeInForce: timeInForce,
          triggerBy: triggerBy,
          closeOnTrigger: closeOnTrigger,
          orderLinkId: orderLinkId);
    }).asyncMap((event) async => await event));
  }

  /// Get user conditional order list.
  /// https://bybit-exchange.github.io/docs/inverse/#t-getcond
  Future<Map<String, dynamic>?> getConditionalOrders(
      {required String symbol,
      String? stopOrderStatus,
      String? direction,
      int? limit,
      String? cursor}) async {
    log.d('ByBitRest.getConditionalOrders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (stopOrderStatus != null) {
      parameters['stop_order_status'] = stopOrderStatus;
    }
    if (direction != null) parameters['direction'] = direction;
    if (limit != null) parameters['limit'] = limit;
    if (cursor != null) parameters['cursor'] = cursor;
    return await request(
        path: '/v2/private/stop-order/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user conditional order list periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-getcond
  void getConditionalOrdersPeriodic(
      {required String symbol,
      String? stopOrderStatus,
      String? direction,
      int? limit,
      String? cursor,
      required Duration period}) {
    log.d('ByBitRest.getConditionalOrdersPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getConditionalOrders(
          symbol: symbol,
          stopOrderStatus: stopOrderStatus,
          direction: direction,
          limit: limit,
          cursor: cursor);
    }).asyncMap((event) async => await event));
  }

  /// Cancel untriggered conditional order.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelcond
  Future<Map<String, dynamic>?> cancelConditionalOrder(
      {required String symbol, String? orderId, String? orderLinkId}) async {
    log.d('ByBitRest.cancelConditionalOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['stop_order_id'] = orderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return await request(
        path: '/v2/private/stop-order/cancel',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Cancel untriggered conditional order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelcond
  void cancelConditionalOrderPeriodic(
      {required String symbol,
      String? orderId,
      String? orderLinkId,
      required Duration period}) {
    log.d('ByBitRest.cancelConditionalOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return cancelConditionalOrder(
          symbol: symbol, orderId: orderId, orderLinkId: orderLinkId);
    }).asyncMap((event) async => await event));
  }

  /// Cancel all untriggered conditional orders.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallcond
  Future<Map<String, dynamic>?> cancelAllConditionalOrders(
      {required String symbol}) async {
    log.d('ByBitRest.cancelAllConditionalOrders');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return await request(
        path: '/v2/private/stop-order/cancelAll',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Cancel all untriggered conditional orders periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallcond
  void cancelAllConditionalOrdersPeriodic(
      {required String symbol, required Duration period}) {
    log.d('ByBitRest.cancelAllConditionalOrdersPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return cancelAllConditionalOrders(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Update conditional order.
  /// https://bybit-exchange.github.io/docs/inverse/#t-replacecond
  Future<Map<String, dynamic>?> updateConditionalOrder({
    required String symbol,
    String? stopOrderId,
    String? orderLinkId,
    int? newOrderQuantity,
    double? newOrderPrice,
    double? newTriggerPrice,
    double? takeProfit,
    double? stopLoss,
    String? tpTriggerBy,
    String? slTriggerBy,
  }) async {
    log.d('ByBitRest.updateConditionalOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (stopOrderId != null) parameters['stop_order_id'] = stopOrderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    if (newOrderQuantity != null) {
      parameters['p_r_qty'] = newOrderQuantity.toString();
    }
    if (newOrderPrice != null) {
      parameters['p_r_price'] = newOrderPrice.toString();
    }
    if (newTriggerPrice != null) {
      parameters['p_r_trigger_price'] = newTriggerPrice.toString();
    }
    if (takeProfit != null) parameters['take_profit'] = takeProfit;
    if (stopLoss != null) parameters['stop_loss'] = stopLoss;
    if (tpTriggerBy != null) parameters['tp_trigger_by'] = tpTriggerBy;
    if (slTriggerBy != null) parameters['sl_trigger_by'] = slTriggerBy;
    return await request(
      path: '/v2/private/stop-order/replace',
      type: 'POST',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Update conditional order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-replacecond
  void updateConditionalOrderPeriodic(
      {required String symbol,
      String? stopOrderId,
      String? orderLinkId,
      int? newOrderQuantity,
      double? newOrderPrice,
      double? newTriggerPrice,
      required Duration period}) {
    log.d('ByBitRest.updateConditionalOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return updateConditionalOrder(
          symbol: symbol,
          stopOrderId: stopOrderId,
          orderLinkId: orderLinkId,
          newOrderQuantity: newOrderQuantity,
          newOrderPrice: newOrderPrice,
          newTriggerPrice: newTriggerPrice);
    }).asyncMap((event) async => await event));
  }

  /// Query conditional order.
  /// https://bybit-exchange.github.io/docs/inverse/#t-querycond
  Future<Map<String, dynamic>?> getConditionalOrder(
      {required String symbol,
      String? stopOrderId,
      String? orderLinkId}) async {
    log.d('ByBitRest.getConditionalOrder');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (stopOrderId != null) parameters['stop_order_id'] = stopOrderId;
    if (orderLinkId != null) parameters['order_link_id'] = orderLinkId;
    return await request(
        path: '/v2/private/stop-order',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Query conditional order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-querycond
  void getConditionalOrderPeriodic(
      {required String symbol,
      String? stopOrderId,
      String? orderLinkId,
      required Duration period}) {
    log.d('ByBitRest.getConditionalOrderPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getConditionalOrder(
          symbol: symbol, stopOrderId: stopOrderId, orderLinkId: orderLinkId);
    }).asyncMap((event) async => await event));
  }

  /// Get user position list.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-myposition
  Future<Map<String, dynamic>?> getPosition({String? symbol}) async {
    log.d('ByBitRest.getPosition');
    var parameters = <String, dynamic>{};
    if (symbol != null) parameters['symbol'] = symbol;
    return await request(
        path: '/v2/private/position/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user position list periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-myposition
  void getPositionPeriodic({String? symbol, required Duration period}) {
    log.d('ByBitRest.getPositionPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getPosition(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Update margin.
  /// https://bybit-exchange.github.io/docs/inverse/#t-changemargin
  Future<Map<String, dynamic>?> setMargin(
      {required String symbol, required double margin}) async {
    log.d('ByBitRest.setMargin');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['margin'] = margin.toString();
    return await request(
        path: '/v2/private/position/change-position-margin',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Update margin periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-changemargin
  void setMarginPeriodic(
      {required String symbol,
      required double margin,
      required Duration period}) {
    log.d('ByBitRest.setMarginPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return setMargin(symbol: symbol, margin: margin);
    }).asyncMap((event) async => await event));
  }

  /// Set trading-stop.
  /// https://bybit-exchange.github.io/docs/inverse/#t-tradingstop
  Future<Map<String, dynamic>?> setTradingStop({
    required String symbol,
    double? takeProfit,
    double? stopLoss,
    double? trailingStop,
    String? tpTriggerBy,
    String? slTriggerBy,
    double? newTrailingTriggerPrice,
    double? tpSize,
    double? slSize,
  }) async {
    log.d('ByBitRest.setTradingStop');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (takeProfit != null) parameters['take_profit'] = takeProfit;
    if (stopLoss != null) parameters['stop_loss'] = stopLoss;
    if (trailingStop != null) parameters['trailing_stop'] = trailingStop;
    if (tpTriggerBy != null) parameters['tp_trigger_by'] = tpTriggerBy;
    if (slTriggerBy != null) parameters['sl_trigger_by'] = slTriggerBy;
    if (tpSize != null) parameters['tp_size'] = tpSize;
    if (slSize != null) parameters['sl_size'] = slSize;
    if (newTrailingTriggerPrice != null) {
      parameters['new_trailing_active'] = newTrailingTriggerPrice;
    }
    return await request(
      path: '/v2/private/position/trading-stop',
      type: 'POST',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Set trading-stop periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-tradingstop
  void setTradingStopPeriodic(
      {required String symbol,
      double? takeProfit,
      double? stopLoss,
      double? trailingStop,
      String? tpTriggerBy,
      String? slTriggerBy,
      double? newTrailingTriggerPrice,
      required Duration period}) {
    log.d('ByBitRest.setTradingStopPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return setTradingStop(
          symbol: symbol,
          takeProfit: takeProfit,
          stopLoss: stopLoss,
          trailingStop: trailingStop,
          tpTriggerBy: tpTriggerBy,
          slTriggerBy: slTriggerBy,
          newTrailingTriggerPrice: newTrailingTriggerPrice);
    }).asyncMap((event) async => await event));
  }

  /// Set leverage.
  /// https://bybit-exchange.github.io/docs/inverse/#t-setleverage
  Future<Map<String, dynamic>?> setLeverage({
    required String symbol,
    required double leverage,
    bool? leverageOnly,
  }) async {
    log.d('ByBitRest.setLeverage');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['leverage'] = leverage;
    if (leverageOnly != null) parameters['leverage_only'] = leverageOnly;
    return await request(
      path: '/v2/private/position/leverage/save',
      type: 'POST',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Set leverage periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-setleverage
  void setLeveragePeriodic(
      {required String symbol,
      required double leverage,
      required Duration period}) {
    log.d('ByBitRest.setLeveragePeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return setLeverage(symbol: symbol, leverage: leverage);
    }).asyncMap((event) async => await event));
  }

  /// Get user's trading records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-usertraderecords
  Future<Map<String, dynamic>?> getUserTradingRecords(
      {required String symbol,
      String? orderId,
      int? startTime,
      int? page,
      int? limit,
      String? order}) async {
    log.d('ByBitRest.getUserTradingRecords');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (orderId != null) parameters['order_id'] = orderId;
    if (startTime != null) parameters['start_time'] = startTime;
    if (page != null) parameters['page'] = page;
    if (limit != null) parameters['limit'] = limit;
    if (order != null) parameters['order'] = order;
    return await request(
        path: '/v2/private/execution/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user's trading records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-usertraderecords
  void getUserTradingRecordsPeriodic(
      {required String symbol,
      String? orderId,
      int? startTime,
      int? page,
      int? limit,
      String? order,
      required Duration period}) {
    log.d('ByBitRest.getUserTradingRecordsPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getUserTradingRecords(
          symbol: symbol,
          orderId: orderId,
          startTime: startTime,
          page: page,
          limit: limit,
          order: order);
    }).asyncMap((event) async => await event));
  }

  /// Get user's closed profit and loss records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-closedprofitandloss
  Future<Map<String, dynamic>?> getUserClosedProfit({
    required String symbol,
    int? startTime,
    int? endTime,
    String? execType,
    int? page,
    int? limit,
  }) async {
    log.d('ByBitRest.getUserClosedProfit');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    if (startTime != null) parameters['start_time'] = startTime;
    if (endTime != null) parameters['end_time'] = endTime;
    if (execType != null) parameters['exec_type'] = execType;
    if (page != null) parameters['page'] = page;
    if (limit != null) parameters['limit'] = limit;
    return await request(
      path: '/v2/private/trade/closed-pnl/list',
      type: 'GET',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Get user's closed profit and loss records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-closedprofitandloss
  void getUserClosedProfitPeriodic({
    required String symbol,
    int? startTime,
    int? endTime,
    String? execType,
    int? page,
    int? limit,
    required Duration period,
  }) {
    log.d('ByBitRest.getUserClosedProfitPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getUserClosedProfit(
        symbol: symbol,
        startTime: startTime,
        endTime: endTime,
        execType: execType,
        page: page,
        limit: limit,
      );
    }).asyncMap((event) async => await event));
  }

  /// Full/Partial Position TP/SL Switch : Switch mode between Full or Partial
  /// https://bybit-exchange.github.io/docs/inverse/#t-switchmode
  Future<Map<String, dynamic>?> fullPartialPositionTPSLSwitch(
      {required String symbol, required String tpSlMode}) async {
    log.d('ByBitRest.crossIsolatedMarginSwitch');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['tp_sl_mode'] = tpSlMode;
    return await request(
      path: '/v2/private/tpsl/switch-mode',
      type: 'POST',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Switch Cross/Isolated; must set leverage value when switching from Cross
  /// to Isolated.
  /// https://bybit-exchange.github.io/docs/inverse/#t-marginswitch
  Future<Map<String, dynamic>?> crossIsolatedMarginSwitch({
    required String symbol,
    required bool isIsolated,
    required double buyLeverage,
    required double sellLeverage,
  }) async {
    log.d('ByBitRest.crossIsolatedMarginSwitch');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['is_isolated'] = isIsolated;
    parameters['buy_leverage'] = buyLeverage;
    parameters['sell_leverage'] = sellLeverage;
    return await request(
      path: '/v2/private/position/switch-isolated',
      type: 'POST',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Query Trading Fee Rate
  /// https://bybit-exchange.github.io/docs/inverse/#t-queryfeerate
  Future<Map<String, dynamic>?> getTradingFeeRate(
      {required String symbol}) async {
    log.d('ByBitRest.crossIsolatedMarginSwitch');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return await request(
      path: '/v2/private/position/fee-rate',
      type: 'POST',
      parameters: parameters,
      withAuthentication: true,
    );
  }

  /// Get risk limit.
  /// https://bybit-exchange.github.io/docs/inverse/#t-risklimit
  Future<Map<String, dynamic>?> getRiskLimit() async {
    log.d('ByBitRest.getRiskLimit');
    return await request(
        path: '/open-api/wallet/risk-limit/list',
        type: 'GET',
        withAuthentication: true);
  }

  /// Get risk limit periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-risklimit
  void getRiskLimitPeriodic({required Duration period}) {
    log.d('ByBitRest.getRiskLimitPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getRiskLimit();
    }).asyncMap((event) async => await event));
  }

  /// Set risk limit.
  /// https://bybit-exchange.github.io/docs/inverse/#t-setrisklimit
  Future<Map<String, dynamic>?> setRiskLimit(
      {required String symbol, required int riskId}) async {
    log.d('ByBitRest.setRiskLimit');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    parameters['risk_id'] = riskId;
    return await request(
        path: '/open-api/wallet/risk-limit',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Set risk limit periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-setrisklimit
  void setRiskLimitPeriodic(
      {required String symbol, required int riskId, required Duration period}) {
    log.d('ByBitRest.setRiskLimitPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return setRiskLimit(symbol: symbol, riskId: riskId);
    }).asyncMap((event) async => await event));
  }

  /// Get the last funding rate.
  /// https://bybit-exchange.github.io/docs/inverse/#t-fundingrate
  Future<Map<String, dynamic>?> getFundingRate({required String symbol}) async {
    log.d('ByBitRest.getFundingRate');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return await request(
        path: '/v2/private/funding/prev-funding-rate',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get the last funding rate periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-fundingrate
  void getFundingRatePeriodic(
      {required String symbol, required Duration period}) {
    log.d('ByBitRest.getFundingRatePeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getFundingRate(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Get previous funding fee.
  /// https://bybit-exchange.github.io/docs/inverse/#t-mylastfundingfee
  Future<Map<String, dynamic>?> getPreviousFundingFee(
      {required String symbol}) async {
    log.d('ByBitRest.getPreviousFundingFee');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return await request(
        path: '/v2/private/funding/prev-funding',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get previous funding fee periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-mylastfundingfee
  void getPreviousFundingFeePeriodic(
      {required String symbol, required Duration period}) {
    log.d('ByBitRest.getPreviousFundingFeePeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getPreviousFundingFee(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Get predicted funding rate and my funding fee.
  /// https://bybit-exchange.github.io/docs/inverse/#t-predictedfunding
  Future<Map<String, dynamic>?> getPredictedFundingRateAndFundingFee(
      {required String symbol}) async {
    log.d('ByBitRest.getPredictedFundingRateAndFundingFee');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return await request(
        path: '/v2/private/funding/predicted-funding',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get predicted funding rate and my funding fee periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-predictedfunding
  void getPredictedFundingRateAndFundingFeePeriodic(
      {required String symbol, required Duration period}) {
    log.d('ByBitRest.getPredictedFundingRateAndFundingFeePeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getPredictedFundingRateAndFundingFee(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Get user's API key information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-key
  Future<Map<String, dynamic>?> getApiKeyInfo() async {
    log.d('ByBitRest.getApiKeyInfo');
    return await request(
        path: '/v2/private/account/api-key',
        type: 'GET',
        withAuthentication: true);
  }

  /// Get user's API key information periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-key
  void getApiKeyInfoPeriodic({required Duration period}) {
    log.d('ByBitRest.getApiKeyInfoPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getApiKeyInfo();
    }).asyncMap((event) async => await event));
  }

  /// Get user's LCP (data refreshes once an hour).
  /// https://bybit-exchange.github.io/docs/inverse/#t-lcp
  Future<Map<String, dynamic>?> getUserLCP({required String symbol}) async {
    log.d('ByBitRest.getUserLCP');
    var parameters = <String, dynamic>{};
    parameters['symbol'] = symbol;
    return await request(
        path: '/v2/private/account/lcp',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get user's LCP (data refreshes once an hour) periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-lcp
  void getUserLCPPeriodic({required String symbol, required Duration period}) {
    log.d('ByBitRest.getUserLCPPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getUserLCP(symbol: symbol);
    }).asyncMap((event) async => await event));
  }

  /// Get wallet balance.
  /// https://bybit-exchange.github.io/docs/inverse/#t-wallet
  Future<Map<String, dynamic>?> getWalletBalance({String? currency}) async {
    log.d('ByBitRest.getWalletBalance');
    var parameters = <String, dynamic>{};
    parameters['coin'] = currency;
    return await request(
        path: '/v2/private/wallet/balance',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get wallet balance periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-wallet
  void getWalletBalancePeriodic({String? currency, required Duration period}) {
    log.d('ByBitRest.getWalletBalancePeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getWalletBalance(currency: currency);
    }).asyncMap((event) async => await event));
  }

  /// Get wallet fund records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-walletrecords
  Future<Map<String, dynamic>?> getWalletFundRecords(
      {String? currency,
      int? startTimestamp,
      int? endTimestamp,
      String? walletFundType,
      int? page,
      int? limit}) async {
    log.d('ByBitRest.getWalletFundRecords');
    var parameters = <String, dynamic>{};
    if (currency != null) parameters['currency'] = currency;
    if (currency != null) parameters['coin'] = currency;
    if (startTimestamp != null) {
      parameters['start_date'] = startTimestamp.toString();
    }
    if (endTimestamp != null) parameters['end_date'] = endTimestamp.toString();
    if (walletFundType != null) parameters['wallet_fund_type'] = walletFundType;
    if (page != null) parameters['page'] = page;
    if (limit != null) parameters['limit'] = limit;
    return await request(
        path: '/v2/private/wallet/fund/records',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get wallet fund records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-walletrecords
  void getWalletFundRecordsPeriodic(
      {String? currency,
      int? startTimestamp,
      int? endTimestamp,
      String? walletFundType,
      int? page,
      int? limit,
      required Duration period}) {
    log.d('ByBitRest.getWalletFundRecordsPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getWalletFundRecords(
          currency: currency,
          startTimestamp: startTimestamp,
          endTimestamp: endTimestamp,
          walletFundType: walletFundType,
          page: page,
          limit: limit);
    }).asyncMap((event) async => await event));
  }

  /// Get withdrawal records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-withdrawrecords
  Future<Map<String, dynamic>?> getWithdrawalRecords(
      {String? currency,
      int? startTimestamp,
      int? endTimestamp,
      String? status,
      int? page,
      int? limit}) async {
    log.d('ByBitRest.getWithdrawalRecords');
    var parameters = <String, dynamic>{};
    if (currency != null) parameters['coin'] = currency;
    if (startTimestamp != null) {
      parameters['start_date'] = startTimestamp.toString();
    }
    if (endTimestamp != null) parameters['end_date'] = endTimestamp.toString();
    if (status != null) parameters['status'] = status;
    if (page != null) parameters['page'] = page;
    if (limit != null) parameters['limit'] = limit;
    return await request(
        path: '/v2/private/wallet/withdraw/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get withdrawal records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-withdrawrecords
  void getWithdrawalRecordsPeriodic(
      {String? currency,
      int? startTimestamp,
      int? endTimestamp,
      String? status,
      int? page,
      int? limit,
      required Duration period}) {
    log.d('ByBitRest.getWithdrawalRecordsPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getWithdrawalRecords(
          currency: currency,
          startTimestamp: startTimestamp,
          endTimestamp: endTimestamp,
          status: status,
          page: page,
          limit: limit);
    }).asyncMap((event) async => await event));
  }

  /// Get asset exchange records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-assetexchangerecords
  Future<Map<String, dynamic>?> getAssetExchangeRecords(
      {String? direction, int? from, int? limit}) async {
    log.d('ByBitRest.getAssetExchangeRecords');
    var parameters = <String, dynamic>{};
    if (from != null) parameters['from'] = from;
    if (direction != null) parameters['direction'] = direction;
    if (limit != null) parameters['limit'] = limit;
    return await request(
        path: '/v2/private/exchange-order/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get asset exchange records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-assetexchangerecords
  void getAssetExchangeRecordsPeriodic(
      {String? direction, int? from, int? limit, required Duration period}) {
    log.d('ByBitRest.getAssetExchangeRecordsPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getAssetExchangeRecords(
          direction: direction, from: from, limit: limit);
    }).asyncMap((event) async => await event));
  }

  /// Get the server time (used for synchronization purposes for example).
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-servertime
  Future<Map<String, dynamic>?> getServerTime() async {
    log.d('ByBitRest.getServerTime');
    return await request(path: '/v2/public/time', type: 'GET');
  }

  /// Get the server time (used for synchronization purposes for example)
  /// periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-servertime
  void getServerTimePeriodic({required Duration period}) {
    log.d('ByBitRest.getServerTimePeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getServerTime();
    }).asyncMap((event) async => await event));
  }

  /// Get Bybit OpenAPI announcements in the last 30 days in reverse order.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-announcement
  Future<Map<String, dynamic>?> getAnnouncement() async {
    log.d('ByBitRest.getAnnouncement');
    return await request(path: '/v2/public/announcement', type: 'GET');
  }

  /// Get Bybit OpenAPI announcements in the last 30 days in reverse order
  /// periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-announcement
  void getAnnouncementPeriodic({required Duration period}) {
    log.d('ByBitRest.getAnnouncementPeriodic');
    streamGroup!.add(Stream.periodic(period, (_) {
      return getAnnouncement();
    }).asyncMap((event) async => await event));
  }
}
