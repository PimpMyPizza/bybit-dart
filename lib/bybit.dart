library bybit;

import 'package:bybit/bybit_rest.dart';
import 'package:bybit/bybit_websocket.dart';
import 'package:flutter/material.dart';
import 'package:bybit/logger.dart';
import 'package:logger/logger.dart';

/// That class opens a WebSocket to communicate with the bybit API
/// You can subscribes to several topics over that WebSocket
/// To see a complete list of all endpoints, see
/// https://bybit-exchange.github.io/docs/inverse/#t-websocket
class ByBit {
  /// Used for the websocket connection with bybit.
  ByBitWebSocket websocket;

  /// Used for the REST communication with bybit.
  ByBitRest rest;

  /// For easy debugging
  LoggerSingleton log;

  static ByBit _instance;

  /// The constructor use default parameters without api-key.
  /// If you want to use all endpoints, you must provite a valid
  /// [key] and [password]. Go to https://www.bybit.com/app/user/api-management
  /// To generate your key. If you're using the websockets, a ping will be
  /// sent every [pingLoopTimer] seconds to the server to maintain connection
  ByBit(
      {String key,
      String password,
      String restUrl,
      int restTimeout,
      String websocketUrl,
      int websocketTimeout,
      int pingLoopTimer,
      String logLevel}) {
    log = LoggerSingleton();
    if (logLevel == 'ERROR')
      Logger.level = Level.error;
    else if (logLevel == 'WARNING')
      Logger.level = Level.warning;
    else if (logLevel == 'INFO')
      Logger.level = Level.info;
    else if (logLevel == 'DEBUG')
      Logger.level = Level.debug;
    else
      Logger.level = Level.nothing;
    websocket = ByBitWebSocket(
        key: key,
        password: password,
        timeout: websocketTimeout,
        url: websocketUrl,
        pingLoopTimer: pingLoopTimer);
    rest = ByBitRest(key: key, password: password, url: restUrl, timeout: restTimeout);
  }

  static ByBit getInstance(
      {String key = '',
      String password = '',
      String restUrl = 'https://api.bybit.com',
      int restTimeout = 3000,
      String websocketUrl = 'wss://stream.bybit.com/realtime',
      int websocketTimeout = 1000,
      int pingLoopTimer = 30,
      String logLevel = 'DEBUG'}) {
    if (_instance == null) {
      _instance = ByBit(
          key: key,
          password: password,
          restTimeout: restTimeout,
          restUrl: restUrl,
          websocketTimeout: websocketTimeout,
          websocketUrl: websocketUrl,
          logLevel: logLevel,
          pingLoopTimer: pingLoopTimer);
      return _instance;
    }
    return _instance;
  }

  /// Connect to the WebSocket server and/or the REST API server
  void connect({bool toWebSocket = true, bool toRestApi = true}) {
    log.i('Connect to Bybit.');
    if (toWebSocket) websocket.connect();
    if (toRestApi) rest.connect();
  }

  /// Disconnect the websocket and http client
  void disconnect() {
    log.i('Disconnect from Bybit.');
    websocket.disconnect();
    rest.disconnect();
  }

  /// Get the server time (used for synchronization purposes for example)
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-servertime
  Future<String> getServerTime() async {
    log.i('Get server time');
    return rest.request(path: '/v2/public/time', type: 'GET');
  }

  /// Get Bybit OpenAPI announcements in the last 30 days in reverse order.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-announcement
  Future<String> getAnnouncement() async {
    log.i('Get annoucements');
    return rest.request(path: '/v2/public/announcement', type: 'GET');
  }

  /// Get the orderbook.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-orderbook
  Future<String> getOrderBook({@required String symbol}) async {
    log.i('Get order book');
    Map<String, dynamic> parameters = Map<String, dynamic>();
    parameters['symbol'] = symbol;
    return rest.request(path: '/v2/public/orderBook/L2', type: 'GET', parameters: parameters);
  }

  /// Get kline. https://bybit-exchange.github.io/docs/inverse/?console#t-querykline
  Future<String> getKLine(
      {@required String symbol,
      @required String interval,
      @required int from,
      int limit = -1}) async {
    log.i('Get KLines for symbol ' + symbol);
    Map<String, dynamic> parameters = Map<String, dynamic>();
    parameters['symbol'] = symbol;
    parameters['interval'] = interval;
    parameters['from'] = from;
    if (limit > 0) parameters['limit'] = limit;
    return rest.request(path: '/v2/public/kline/list', type: 'GET', parameters: parameters);
  }

  /// Get the latest information for symbol.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-latestsymbolinfo
  Future<String> getTickers({String symbol}) {
    log.i('Get tickers');
    Map<String, dynamic> parameters = Map<String, dynamic>();
    if (symbol != null) parameters['symbol'] = symbol;
    return rest.request(path: '/v2/public/tickers', type: 'GET', parameters: parameters);
  }

  /// Get recent trades.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-publictradingrecords
  Future<String> getTradingRecords({@required String symbol, int from, int limit}) {
    log.i('Get trading records');
    Map<String, dynamic> parameters = Map<String, dynamic>();
    parameters['symbol'] = symbol;
    if (from != null) parameters['from'] = from;
    if (limit != null) parameters['limit'] = limit;
    return rest.request(path: '/v2/public/trading-records', type: 'GET', parameters: parameters);
  }

  /// Get symbol info.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  Future<String> getSymbolsInfo() {
    log.i('Get symbols information');
    return rest.request(path: '/v2/public/symbols', type: 'GET');
  }

  /// Retrieve the liquidated orders, The query range is the last seven days of data.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  Future<String> getLiquidatedOrders(
      {@required String symbol, int from, int limit, int startTime, int endTime}) {
    log.i('Get the liquidated orders');
    Map<String, dynamic> parameters = Map<String, dynamic>();
    parameters['symbol'] = symbol;
    if (from != null) parameters['from'] = from;
    if (limit != null) parameters['limit'] = limit;
    if (startTime != null) parameters['start_time'] = startTime;
    if (endTime != null) parameters['end_time'] = endTime;
    return rest.request(path: '/v2/public/liq-records', type: 'GET', parameters: parameters);
  }

  /// Place active order
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive
  Future<String> placeActiveOrder(
      {@required String symbol,
      @required String side,
      @required String orderType,
      @required int quantity,
      @required String timeInForce,
      double price,
      double takeProfit,
      double stopLoss,
      bool reduceOnly,
      bool closeOnTrigger,
      String orderLinkId}) {
    log.i('Place an active order');
    Map<String, dynamic> parameters = Map<String, dynamic>();
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
    return rest.request(
        path: '/v2/private/order/create',
        type: 'POST',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get active order
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive
  Future<String> getActiveOrder(
      {@required String symbol,
      String orderStatus,
      String direction,
      int limit,
      String cursor}) async {
    log.i('Get user active order list');
    Map<String, dynamic> parameters = Map<String, dynamic>();
    parameters['symbol'] = symbol;
    if (orderStatus != null) parameters['order_status'] = orderStatus;
    if (direction != null) parameters['direction'] = direction;
    if (limit != null) parameters['limit'] = limit;
    if (cursor != null) parameters['cursor'] = cursor;
    return rest.request(
        path: '/v2/private/order/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Get position list
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-myposition
  Future<String> getPosition({String symbol}) async {
    Map<String, dynamic> parameters = Map<String, dynamic>();
    if (symbol != null) parameters['symbol'] = symbol;
    return rest.request(
        path: '/v2/private/position/list',
        type: 'GET',
        parameters: parameters,
        withAuthentication: true);
  }

  /// Send ping to the WebSocket server
  void ping() {
    log.i('Send ping');
    websocket.ping();
  }

  /// Subscribe to the KLines channel. A list of valid [interval] values string
  /// is at: https://bybit-exchange.github.io/docs/inverse/#t-websocketklinev2
  void subscribeToKlines({@required String symbol, @required String interval}) {
    log.i('Subscribe to KLines with symbol: ' + symbol + ' and interval: ' + interval);
    websocket.subscribeTo(topic: 'klineV2', symbol: symbol, filter: interval);
  }

  /// Fetches the orderbook with a [depth] of '25' or '200' orders per side.
  /// is at: https://bybit-exchange.github.io/docs/inverse/#t-websocketorderbook25
  void subscribeToOrderBook({@required int depth, String symbol = ''}) {
    log.i('Subscribe to orderbook with depth : ' + depth.toString() + ' for the symbol: ' + symbol);
    websocket.subscribeTo(topic: 'orderBookL2_' + depth.toString(), symbol: symbol);
  }

  /// Get real-time trading information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websockettrade
  void subscribeToTrades({String symbol = ''}) {
    log.i('Subscribe to trades.');
    websocket.subscribeTo(topic: 'trade', symbol: symbol);
  }

  /// Get the daily insurance fund update.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketinsurance
  void subscribeToInsurance({String currency = ''}) {
    log.i('Subscribe to insurance.');
    websocket.subscribeTo(topic: 'insurance', symbol: currency);
  }

  /// Get latest information for symbol.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketinstrumentinfo
  void subscribeToInstrumentInfo({@required String symbol}) {
    log.i('Subscribe to the latest symbol information.');
    websocket.subscribeTo(topic: 'instrument_info.100ms', symbol: symbol);
  }

  /// Subscribe to the position channel. You need to have a valid api-key
  /// in order to receive a valid response from the server
  void subscribeToPosition() {
    log.i('Subscribe to position');
    websocket.subscribeTo(topic: 'position');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketexecution
  void subscribeToExecution() {
    log.i('Subscribe to execution');
    websocket.subscribeTo(topic: 'execution');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketorder
  void subscribeToOrder() {
    log.i('Subscribe to order');
    websocket.subscribeTo(topic: 'order');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketstoporder
  void subscribeToStopOrder() {
    log.i('Subscribe to stop_order');
    websocket.subscribeTo(topic: 'stop_order');
  }
}
