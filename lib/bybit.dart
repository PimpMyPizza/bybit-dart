library bybit;

import 'dart:io';

import 'package:bybit/bybit_state.dart';
import 'package:bybit/bybit_rest.dart';
import 'package:bybit/bybit_websocket.dart';
import 'package:meta/meta.dart';
import 'package:bybit/logger.dart';
import 'package:logger/logger.dart';
import 'package:async/async.dart' show StreamGroup;

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

  /// Stream that remaps the websocket and periodic REST calls into
  /// one stream output of json.
  Stream<Map<String, dynamic>> stream;

  /// Try to reconnect if the websocket closes unexpectly
  bool autoreconnect;

  String key;
  String password;
  String websocketUrl;
  int pingPeriod;
  var timeout = Duration(seconds: 60);
  String restUrl;

  StreamGroup<Map<String, dynamic>> streamGroup;

  ByBitState state;

  var _saveState = true;

  /// The constructor use default parameters without api-key.
  /// If you want to use all endpoints, you must provite a valid
  /// [key] and [password]. Go to https://www.bybit.com/app/user/api-management
  /// To generate your key. If you're using the websockets, a ping will be
  /// sent every [pingPeriod] seconds to the server to maintain connection.
  /// If no message is received from the Server within [timeout] seconds,
  /// an automatic reconnection can be enabled with [autoreconnect].
  ByBit(
      {this.key = '',
      this.password = '',
      this.restUrl = 'https://api.bybit.com',
      this.websocketUrl = 'wss://stream.bybit.com/realtime',
      this.timeout,
      this.pingPeriod = 30,
      String logLevel = 'WARNING',
      this.autoreconnect = true}) {
    if (logLevel == 'ERROR') {
      Logger.level = Level.error;
    } else if (logLevel == 'WARNING') {
      Logger.level = Level.warning;
    } else if (logLevel == 'INFO') {
      Logger.level = Level.info;
    } else if (logLevel == 'DEBUG') {
      Logger.level = Level.debug;
    } else {
      Logger.level = Level.nothing;
    }
    log = LoggerSingleton();
    state = ByBitState();
    websocket = ByBitWebSocket(
        key: key,
        password: password,
        timeout: timeout,
        url: websocketUrl,
        pingPeriod: pingPeriod);
    rest =
        ByBitRest(key: key, password: password, url: restUrl, timeout: timeout);
  }

  /// Connect to the WebSocket server and/or the REST API server
  void connect({bool toWebSocket = true, bool toRestApi = true}) {
    log.i('Connect to Bybit.');
    streamGroup = StreamGroup();
    if (toWebSocket) {
      websocket.connect();
      streamGroup.add(websocket.controller.stream);
    }
    if (toRestApi) {
      rest.connect();
      streamGroup.add(rest.stream);
    }
    stream = streamGroup.stream.asBroadcastStream();
    stream.listen((event) {
      if (event['error'] != null) {
        if (event['error'] == 'ws_timeout') {
          log.e('ByBitWebSocket stream timeout.');
          //streamGroup.remove(websocket.controller.stream);
          if (autoreconnect == true) {
            log.w('Trying to reconnect with the WebSocket server');
            sleep(Duration(milliseconds: 500));
            websocket.connect();
            streamGroup.add(websocket.controller.stream);
            // temporaly disable state saving for the reconnection
            _saveState = false;
            if (state.ws.isSubscribedToOrder) {
              subscribeToOrder();
            }
            if (state.ws.isSubscribedToKlines) {
              state.ws.paramKlines.forEach((param) {
                subscribeToKlines(
                    symbol: param.symbol, interval: param.interval);
              });
            }
            if (state.ws.isSubscribedToOrderBook) {
              state.ws.paramOrderBook.forEach((param) {
                subscribeToOrderBook(depth: param.depth, symbol: param.symbol);
              });
            }
            if (state.ws.isSubscribedToTrades) {
              state.ws.paramTrades.forEach((param) {
                subscribeToTrades(symbol: param.symbol);
              });
            }
            if (state.ws.isSubscribedToInsurance) {
              state.ws.paramInsurance.forEach((param) {
                subscribeToInsurance(currency: param.currency);
              });
            }
            if (state.ws.isSubscribedToInstrumentInfo) {
              state.ws.paramInstrumentInfo.forEach((param) {
                subscribeToInstrumentInfo(symbol: param.symbol);
              });
            }
            if (state.ws.isSubscribedToPosition) {
              subscribeToPosition();
            }
            if (state.ws.isSubscribedToExecution) {
              subscribeToExecution();
            }
            if (state.ws.isSubscribedToStopOrder) {
              subscribeToOrder();
            }
            if (state.ws.isSubscribedToOrder) {
              subscribeToStopOrder();
            }
            _saveState = true;
          }
        } else {
          log.e('Unexpected WebSocket stream fail.');
        }
      }
    }, onDone: () {
      print('ON DONE !!!');
    }, onError: (e) {
      print('ON ERROR !!!' + e.toString());
      websocket.disconnect();
    });
  }

  /// Disconnect the websocket and http client
  void disconnect() {
    log.i('Disconnect from Bybit.');
    websocket.disconnect();
    rest.disconnect();
  }

  /// Get the orderbook.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-orderbook
  Future<Map<String, dynamic>> getOrderBook({@required String symbol}) async {
    log.i('Get order book');
    return await rest.getOrderBook(symbol: symbol);
  }

  /// Add a periodic call to the order book REST API.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-orderbook
  void getOrderBookPeriodic({@required String symbol, Duration period}) {
    log.i('Add a periodic call to the order book REST API.');
    rest.getOrderBookPeriodic(symbol: symbol, period: period);
  }

  /// Get kline. https://bybit-exchange.github.io/docs/inverse/?console#t-querykline
  Future<Map<String, dynamic>> getKLine(
      {@required String symbol,
      @required String interval,
      @required int from,
      int limit = -1}) async {
    log.i('Get KLines for symbol ' + symbol);
    return await rest.getKLine(
        symbol: symbol, interval: interval, from: from, limit: limit);
  }

  /// Get kline periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querykline
  void getKLinePeriodic(
      {@required String symbol,
      @required String interval,
      @required int from,
      int limit,
      Duration period}) async {
    log.i('Get kline periodically. ' + symbol);
    rest.getKLinePeriodic(
        period: period,
        symbol: symbol,
        interval: interval,
        from: from,
        limit: limit);
  }

  /// Get the latest information for symbol.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-latestsymbolinfo
  Future<Map<String, dynamic>> getTickers({String symbol}) async {
    log.i('Get tickers.');
    return await rest.getTickers(symbol: symbol);
  }

  /// Get the latest information for symbols periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-latestsymbolinfo
  void getTickersPeriodic({String symbol, @required Duration period}) {
    log.i('Get tickers periodically.');
    rest.getTickersPeriodic(period: period, symbol: symbol);
  }

  /// Get recent trades.
  ///
  /// Returns the last trades from a trade id [from] with a limit of [limit]
  /// trades. If no [from] value is given, the latest [limit] trades will be
  /// returned (default [limit]: 500, max: 1000)
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-publictradingrecords
  Future<Map<String, dynamic>> getTradingRecords(
      {@required String symbol, int from, int limit}) async {
    log.i('Get trading records');
    return await rest.getTradingRecords(
        symbol: symbol, from: from, limit: limit);
  }

  /// Get recent trades periodically.
  ///
  /// Returns the last trades from a trade id [from] with a limit of [limit]
  /// trades. If no [from] value is given, the latest [limit] trades will be
  /// returned (default [limit]: 500, max: 1000)
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-publictradingrecords
  void getTradingRecordsPeriodic(
      {@required String symbol,
      int from,
      int limit,
      @required Duration period}) {
    log.i('Get recent trades periodically.');
    rest.getTradingRecordsPeriodic(
        period: period, symbol: symbol, from: from, limit: limit);
  }

  /// Get the information for all symbols.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  Future<Map<String, dynamic>> getSymbolsInfo() async {
    log.i('Get symbols information');
    return await rest.getSymbolsInfo();
  }

  /// Get the information for all symbols periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  void getSymbolsInfoPeriodic({@required Duration period}) {
    log.i('Get the information for all symbols periodically.');
    rest.getSymbolsInfoPeriodic(period: period);
  }

  /// Retrieve the liquidated orders.
  ///
  /// The query range is the last seven days of data. You can pass the [startTime]
  /// and [endTime] timestamps (in milliseconds) or a trade-id ([from]) and/or
  /// a [limit] (max 1000, default 500).
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  Future<Map<String, dynamic>> getLiquidatedOrders(
      {@required String symbol,
      int from,
      int limit,
      int startTime,
      int endTime}) async {
    log.i('Get the liquidated orders');
    return await rest.getLiquidatedOrders(
        symbol: symbol,
        from: from,
        limit: limit,
        startTime: startTime,
        endTime: endTime);
  }

  /// Retrieve the liquidated orders periodically
  ///
  /// The query range is the last seven days of data. You can pass the [startTime]
  /// and [endTime] timestamps (in milliseconds) or a trade-id ([from]) and/or
  /// a [limit] (max 1000, default 500).
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol
  void getLiquidatedOrdersPeriodic(
      {@required String symbol,
      int from,
      int limit,
      int startTime,
      int endTime,
      Duration period}) {
    log.i('Retrieve the liquidated orders periodically.');
    rest.getLiquidatedOrdersPeriodic(
        symbol: symbol,
        from: from,
        limit: limit,
        startTime: startTime,
        endTime: endTime,
        period: period);
  }

  /// Query mark price kline (like Query Kline but for mark price).
  ///
  /// https://bybit-exchange.github.io/docs/inverse/#t-markpricekline
  Future<Map<String, dynamic>> getMarkPriceKLine(
      {@required String symbol,
      @required String interval,
      @required int from,
      int limit}) async {
    log.i('Get the liquidated orders');
    return await rest.getMarkPriceKLine(
        symbol: symbol, interval: interval, from: from, limit: limit);
  }

  /// Query mark price kline (like Query Kline but for mark price) periodically
  ///
  /// https://bybit-exchange.github.io/docs/inverse/#t-markpricekline
  void getMarkPriceKLinePeriodic(
      {@required String symbol,
      @required String interval,
      @required int from,
      int limit,
      Duration period}) {
    log.i('Query mark price kline periodically');
    rest.getMarkPriceKLinePeriodic(
        symbol: symbol,
        interval: interval,
        from: from,
        limit: limit,
        period: period);
  }

  /// Gets the total amount of unsettled contracts. In other words, the total
  /// number of contracts held in open positions.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<Map<String, dynamic>> getOpenInterest(
      {@required String symbol, @required String interval, int limit}) async {
    log.i('Get the open orders');
    return await rest.getOpenInterest(
        symbol: symbol, interval: interval, limit: limit);
  }

  /// Gets the total amount of unsettled contracts periodically.
  /// In other words, get the total number of contracts held in open positions
  /// every [period].
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  void getOpenInterestPeriodic(
      {@required String symbol,
      @required String interval,
      int limit,
      Duration period}) {
    log.i('Get the open orders periodically');
    rest.getOpenInterestPeriodic(
        symbol: symbol, interval: interval, limit: limit, period: period);
  }

  /// Obtain filled orders worth more than 500,000 USD within the last 24h.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<Map<String, dynamic>> getLatestBigDeals(
      {@required String symbol, int limit}) async {
    log.i('Get the latest big deals.');
    return await rest.getLatestBigDeals(symbol: symbol, limit: limit);
  }

  /// Obtain filled orders worth more than 500,000 USD within the last 24h,
  /// periodically.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  void getLatestBigDealsPeriodic(
      {@required String symbol, int limit, @required Duration period}) {
    log.i('Subscribe to the latest big deals.');
    rest.getLatestBigDealsPeriodic(
        symbol: symbol, limit: limit, period: period);
  }

  /// Gets the Bybit user accounts' long-short ratio.
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  Future<Map<String, dynamic>> getLongShortRatio(
      {@required String symbol, @required String interval, int limit}) async {
    log.i('Get the long-short ratio');
    return await rest.getLongShortRatio(
        symbol: symbol, interval: interval, limit: limit);
  }

  /// Gets the Bybit user accounts' long-short ratio periodically
  ///
  /// [period] must be one of the followin strings :
  /// '5min', '15min', '30min', '1h', '4h', '1d'
  /// https://bybit-exchange.github.io/docs/inverse/#t-marketopeninterest
  void getLongShortRatioPeriodic(
      {@required String symbol,
      @required String interval,
      int limit,
      Duration period}) {
    log.i('Subscribe to the long-short ratio');
    rest.getLongShortRatioPeriodic(
        symbol: symbol, interval: interval, limit: limit, period: period);
  }

  /// Place active order
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive
  Future<Map<String, dynamic>> placeActiveOrder(
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
      String orderLinkId}) async {
    log.i('Place an active order');
    return await rest.placeActiveOrder(
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
  }

  /// Place active order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive
  void placeActiveOrderPeriodic(
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
      String orderLinkId,
      Duration period}) {
    log.i('Place an active order periodically');
    rest.placeActiveOrderPeriodic(
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
        orderLinkId: orderLinkId,
        period: period);
  }

  /// Get active order
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-getactive
  Future<Map<String, dynamic>> getActiveOrder(
      {@required String symbol,
      String orderStatus,
      String direction,
      int limit,
      String cursor}) async {
    log.i('Get user active order list');
    return await rest.getActiveOrder(
        symbol: symbol,
        orderStatus: orderStatus,
        direction: direction,
        limit: limit,
        cursor: cursor);
  }

  /// Get active order periodically
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-getactive
  void getActiveOrderPeriodic(
      {@required String symbol,
      String orderStatus,
      String direction,
      int limit,
      String cursor,
      Duration period}) {
    log.i('Subscribe to user active order list');
    rest.getActiveOrderPeriodic(
        symbol: symbol,
        orderStatus: orderStatus,
        direction: direction,
        limit: limit,
        cursor: cursor,
        period: period);
  }

  /// Cancel active order. Note that either orderId or orderLinkId are required
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelactive
  Future<Map<String, dynamic>> cancelActiveOrder(
      {@required String symbol, String orderId, String orderLinkId}) async {
    log.i('Cancel active order');
    return await rest.cancelActiveOrder(
        symbol: symbol, orderId: orderId, orderLinkId: orderLinkId);
  }

  /// Cancel active order periodically. Note that either orderId or orderLinkId
  /// are required https://bybit-exchange.github.io/docs/inverse/#t-cancelactive
  void cancelActiveOrderPeriodic(
      {@required String symbol,
      String orderId,
      String orderLinkId,
      Duration period}) {
    log.i('Cancel active order periodically');
    rest.cancelActiveOrderPeriodic(
        symbol: symbol,
        orderId: orderId,
        orderLinkId: orderLinkId,
        period: period);
  }

  /// Cancel all active orders that are unfilled or partially filled. Fully
  /// filled orders cannot be cancelled.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallactive
  Future<Map<String, dynamic>> cancelAllActiveOrders(
      {@required String symbol}) async {
    log.i('Cancel all active orders');
    return await rest.cancelAllActiveOrders(symbol: symbol);
  }

  /// Cancel all active orders that are unfilled or partially filled periodically.
  /// Fully filled orders cannot be cancelled.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallactive
  void cancelAllActiveOrdersPeriodic(
      {@required String symbol, @required Duration period}) {
    log.i('Cancel all active orders periodically.');
    rest.cancelAllActiveOrdersPeriodic(symbol: symbol, period: period);
  }

  /// Replace order can modify/amend your active orders.
  /// https://bybit-exchange.github.io/docs/inverse/#t-replaceactive
  Future<Map<String, dynamic>> updateActiveOrder(
      {@required String symbol,
      String orderId,
      String orderLinkId,
      double newOrderQuantity,
      double newOrderPrice}) async {
    log.i('Replace/update active order.');
    return await rest.updateActiveOrder(
        symbol: symbol,
        orderId: orderId,
        orderLinkId: orderLinkId,
        newOrderQuantity: newOrderQuantity,
        newOrderPrice: newOrderPrice);
  }

  /// Replace order can modify/amend your active orders periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-replaceactive
  void updateActiveOrderPeriodic(
      {@required String symbol,
      String orderId,
      String orderLinkId,
      double newOrderQuantity,
      double newOrderPrice,
      Duration period}) {
    log.i('Replace/update active order periodically.');
    rest.updateActiveOrderPeriodic(
        symbol: symbol,
        orderId: orderId,
        orderLinkId: orderLinkId,
        newOrderQuantity: newOrderQuantity,
        newOrderPrice: newOrderPrice,
        period: period);
  }

  /// Query real-time active order information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-queryactive
  Future<Map<String, dynamic>> getRealTimeActiveOrder(
      {@required String symbol, String orderId, String orderLinkId}) async {
    log.i('Query real-time active order information');
    return await rest.getRealTimeActiveOrder(
        symbol: symbol, orderId: orderId, orderLinkId: orderLinkId);
  }

  /// Query real-time active order information periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-queryactive
  void getRealTimeActiveOrderPeriodic(
      {@required String symbol,
      String orderId,
      String orderLinkId,
      Duration period}) {
    log.i('Query real-time active order information periodically');
    rest.getRealTimeActiveOrderPeriodic(
        symbol: symbol,
        orderId: orderId,
        orderLinkId: orderLinkId,
        period: period);
  }

  /// Place a market price conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-placecond
  Future<Map<String, dynamic>> placeConditionalOrder(
      {@required String symbol,
      @required String side,
      @required String orderType,
      @required int quantity,
      double price,
      @required double basePrice,
      @required double triggerPrice,
      @required String timeInForce,
      @required String triggerBy,
      bool closeOnTrigger,
      String orderLinkId}) async {
    log.i('Place conditional Order.');
    return await rest.placeConditionalOrder(
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
  }

  /// Place a market price conditional order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-placecond
  void placeConditionalOrderPeriodic(
      {@required String symbol,
      @required String side,
      @required String orderType,
      @required int quantity,
      double price,
      @required double basePrice,
      @required double triggerPrice,
      @required String timeInForce,
      @required String triggerBy,
      bool closeOnTrigger,
      String orderLinkId,
      Duration period}) {
    log.i('Place conditional Order periodically.');
    rest.placeConditionalOrderPeriodic(
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
        orderLinkId: orderLinkId,
        period: period);
  }

  /// Get user conditional order list.
  /// https://bybit-exchange.github.io/docs/inverse/#t-getcond
  Future<Map<String, dynamic>> getConditionalOrders(
      {@required String symbol,
      String stopOrderStatus,
      String direction,
      int limit,
      String cursor}) async {
    log.i('Get user conditional order list.');
    return await rest.getConditionalOrders(
        symbol: symbol,
        stopOrderStatus: stopOrderStatus,
        direction: direction,
        limit: limit,
        cursor: cursor);
  }

  /// Get user conditional order list periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-getcond
  void getConditionalOrdersPeriodic(
      {@required String symbol,
      String stopOrderStatus,
      String direction,
      int limit,
      String cursor,
      Duration period}) {
    log.i('Get user conditional order list periodically.');
    rest.getConditionalOrdersPeriodic(
        symbol: symbol,
        stopOrderStatus: stopOrderStatus,
        direction: direction,
        limit: limit,
        cursor: cursor,
        period: period);
  }

  /// Cancel untriggered conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelcond
  Future<Map<String, dynamic>> cancelConditionalOrder(
      {@required String symbol, String orderId, String orderLinkId}) async {
    log.i('Cancel conditional order');
    return await rest.cancelConditionalOrder(
        symbol: symbol, orderId: orderId, orderLinkId: orderLinkId);
  }

  /// Cancel untriggered conditional order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelcond
  void cancelConditionalOrderPeriodic(
      {@required String symbol,
      String orderId,
      String orderLinkId,
      Duration period}) {
    log.i('Cancel conditional order periodically.');
    rest.cancelConditionalOrderPeriodic(
        symbol: symbol,
        orderId: orderId,
        orderLinkId: orderLinkId,
        period: period);
  }

  /// Cancel all untriggered conditional orders
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallcond
  Future<Map<String, dynamic>> cancelAllConditionalOrders(
      {@required String symbol}) async {
    log.i('Cancel all conditional orders');
    return await rest.cancelAllConditionalOrders(symbol: symbol);
  }

  /// Cancel all untriggered conditional orders periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-cancelallcond
  void cancelAllConditionalOrdersPeriodic(
      {@required String symbol, @required Duration period}) {
    log.i('Cancel all conditional orders periodically.');
    rest.cancelAllConditionalOrdersPeriodic(symbol: symbol, period: period);
  }

  /// Update conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-replacecond
  Future<Map<String, dynamic>> updateConditionalOrder(
      {@required String symbol,
      String stopOrderId,
      String orderLinkId,
      int newOrderQuantity,
      double newOrderPrice,
      double newTriggerPrice}) async {
    log.i('Update conditional order');
    return await rest.updateConditionalOrder(
        symbol: symbol,
        stopOrderId: stopOrderId,
        orderLinkId: orderLinkId,
        newOrderQuantity: newOrderQuantity,
        newOrderPrice: newOrderPrice,
        newTriggerPrice: newTriggerPrice);
  }

  /// Update conditional order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-replacecond
  void updateConditionalOrderPeriodic(
      {@required String symbol,
      String stopOrderId,
      String orderLinkId,
      int newOrderQuantity,
      double newOrderPrice,
      double newTriggerPrice,
      Duration period}) {
    log.i('Update conditional order periodically.');
    rest.updateConditionalOrderPeriodic(
        symbol: symbol,
        stopOrderId: stopOrderId,
        orderLinkId: orderLinkId,
        newOrderQuantity: newOrderQuantity,
        newOrderPrice: newOrderPrice,
        newTriggerPrice: newTriggerPrice,
        period: period);
  }

  /// Query conditional order
  /// https://bybit-exchange.github.io/docs/inverse/#t-querycond
  Future<Map<String, dynamic>> getConditionalOrder(
      {@required String symbol, String stopOrderId, String orderLinkId}) async {
    log.i('Query conditional order');
    return await rest.getConditionalOrder(
        symbol: symbol, stopOrderId: stopOrderId, orderLinkId: orderLinkId);
  }

  /// Query conditional order periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-querycond
  void getConditionalOrderPeriodic(
      {@required String symbol,
      String stopOrderId,
      String orderLinkId,
      Duration period}) {
    log.i('Query conditional order periodically.');
    rest.getConditionalOrderPeriodic(
        symbol: symbol,
        stopOrderId: stopOrderId,
        orderLinkId: orderLinkId,
        period: period);
  }

  /// Get user position list
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-myposition
  Future<Map<String, dynamic>> getPosition({String symbol}) async {
    log.i('Get user position list.');
    return await rest.getPosition(symbol: symbol);
  }

  /// Get user position list periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-myposition
  void getPositionPeriodic({String symbol, @required Duration period}) {
    log.i('Get user position list periodically.');
    rest.getPositionPeriodic(symbol: symbol, period: period);
  }

  /// Update margin
  /// https://bybit-exchange.github.io/docs/inverse/#t-changemargin
  Future<Map<String, dynamic>> setMargin(
      {@required String symbol, @required double margin}) async {
    log.i('Update margin');
    return await rest.setMargin(symbol: symbol, margin: margin);
  }

  /// Update margin periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-changemargin
  void setMarginPeriodic(
      {@required String symbol,
      @required double margin,
      @required Duration period}) {
    log.i('Update margin periodically');
    rest.setMarginPeriodic(symbol: symbol, margin: margin, period: period);
  }

  /// Set trading-stop
  /// https://bybit-exchange.github.io/docs/inverse/#t-tradingstop
  Future<Map<String, dynamic>> setTradingStop(
      {@required String symbol,
      double takeProfit,
      double stopLoss,
      double trailingStop,
      String tpTriggerBy,
      String slTriggerBy,
      double newTrailingTriggerPrice}) async {
    log.i('Set trading stop.');
    return await rest.setTradingStop(
        symbol: symbol,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
        trailingStop: trailingStop,
        tpTriggerBy: tpTriggerBy,
        slTriggerBy: slTriggerBy,
        newTrailingTriggerPrice: newTrailingTriggerPrice);
  }

  /// Set trading-stop periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-tradingstop
  void setTradingStopPeriodic(
      {@required String symbol,
      double takeProfit,
      double stopLoss,
      double trailingStop,
      String tpTriggerBy,
      String slTriggerBy,
      double newTrailingTriggerPrice,
      Duration period}) {
    log.i('Set trading stop periodically.');
    rest.setTradingStopPeriodic(
        symbol: symbol,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
        trailingStop: trailingStop,
        tpTriggerBy: tpTriggerBy,
        slTriggerBy: slTriggerBy,
        newTrailingTriggerPrice: newTrailingTriggerPrice,
        period: period);
  }

  /// Set leverage
  /// https://bybit-exchange.github.io/docs/inverse/#t-setleverage
  Future<Map<String, dynamic>> setLeverage(
      {@required String symbol, @required double leverage}) async {
    log.i('Set leverage.');
    return await rest.setLeverage(symbol: symbol, leverage: leverage);
  }

  /// Set leverage periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-setleverage
  void setLeveragePeriodic(
      {@required String symbol,
      @required double leverage,
      @required Duration period}) {
    log.i('Set leverage periodically.');
    rest.setLeveragePeriodic(
        symbol: symbol, leverage: leverage, period: period);
  }

  /// Get user's trading records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-usertraderecords
  Future<Map<String, dynamic>> getUserTradingRecords(
      {@required String symbol,
      String orderId,
      int startTime,
      int page,
      int limit,
      String order}) async {
    log.i('Get user trading records.');
    return await rest.getUserTradingRecords(
        symbol: symbol,
        orderId: orderId,
        startTime: startTime,
        page: page,
        limit: limit,
        order: order);
  }

  /// Get user's trading records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-usertraderecords
  void getUserTradingRecordsPeriodic(
      {@required String symbol,
      String orderId,
      int startTime,
      int page,
      int limit,
      String order,
      Duration period}) {
    log.i('Get user trading records periodically.');
    rest.getUserTradingRecordsPeriodic(
        symbol: symbol,
        orderId: orderId,
        startTime: startTime,
        page: page,
        limit: limit,
        order: order,
        period: period);
  }

  /// Get user's closed profit and loss records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-closedprofitandloss
  Future<Map<String, dynamic>> getUserClosedProfit(
      {@required String symbol,
      int startTime,
      int endTime,
      String execType,
      int page,
      int limit}) async {
    log.i('Get user closed profit (PNL).');
    return await rest.getUserClosedProfit(
        symbol: symbol,
        startTime: startTime,
        endTime: endTime,
        execType: execType,
        page: page,
        limit: limit);
  }

  /// Get user's closed profit and loss records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-closedprofitandloss
  void getUserClosedProfitPeriodic(
      {@required String symbol,
      int startTime,
      int endTime,
      String execType,
      int page,
      int limit,
      Duration period}) {
    log.i('Get user closed profit (PNL) periodically.');
    rest.getUserClosedProfitPeriodic(
        symbol: symbol,
        startTime: startTime,
        endTime: endTime,
        execType: execType,
        page: page,
        limit: limit,
        period: period);
  }

  /// Get risk limit
  /// https://bybit-exchange.github.io/docs/inverse/#t-risklimit
  Future<Map<String, dynamic>> getRiskLimit() async {
    log.i('Get risk limit.');
    return await rest.getRiskLimit();
  }

  /// Get risk limit periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-risklimit
  void getRiskLimitPeriodic({@required Duration period}) {
    log.i('Get risk limit periodically.');
    rest.getRiskLimitPeriodic(period: period);
  }

  /// Set risk limit
  /// https://bybit-exchange.github.io/docs/inverse/#t-setrisklimit
  Future<Map<String, dynamic>> setRiskLimit(
      {@required String symbol, @required int riskId}) async {
    log.i('Set risk limit.');
    return await rest.setRiskLimit(symbol: symbol, riskId: riskId);
  }

  /// Set risk limit periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-setrisklimit
  void setRiskLimitPeriodic(
      {@required String symbol,
      @required int riskId,
      @required Duration period}) {
    log.i('Set risk limit periodically');
    rest.setRiskLimitPeriodic(symbol: symbol, riskId: riskId, period: period);
  }

  /// Get the last funding rate
  /// https://bybit-exchange.github.io/docs/inverse/#t-fundingrate
  Future<Map<String, dynamic>> getFundingRate({@required String symbol}) async {
    log.i('Get funding rate.');
    return await rest.getFundingRate(symbol: symbol);
  }

  /// Get the last funding rate periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-fundingrate
  void getFundingRatePeriodic(
      {@required String symbol, @required Duration period}) {
    log.i('Get funding rate periodically.');
    rest.getFundingRatePeriodic(symbol: symbol, period: period);
  }

  /// Get previous funding fee
  /// https://bybit-exchange.github.io/docs/inverse/#t-mylastfundingfee
  Future<Map<String, dynamic>> getPreviousFundingFee(
      {@required String symbol}) async {
    log.i('Get previous funding fee.');
    return await rest.getPreviousFundingFee(symbol: symbol);
  }

  /// Get previous funding fee periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-mylastfundingfee
  void getPreviousFundingFeePeriodic(
      {@required String symbol, @required Duration period}) {
    log.i('Get previous funding fee periodically.');
    rest.getPreviousFundingFeePeriodic(symbol: symbol, period: period);
  }

  /// Get predicted funding rate and my funding fee.
  /// https://bybit-exchange.github.io/docs/inverse/#t-predictedfunding
  Future<Map<String, dynamic>> getPredictedFundingRateAndFundingFee(
      {@required String symbol}) async {
    log.i('Get predicted funding rate and funding fee.');
    return await rest.getPredictedFundingRateAndFundingFee(symbol: symbol);
  }

  /// Get predicted funding rate and my funding fee periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-predictedfunding
  void getPredictedFundingRateAndFundingFeePeriodic(
      {@required String symbol, @required Duration period}) {
    log.i('Get predicted funding rate and funding fee periodically.');
    rest.getPredictedFundingRateAndFundingFeePeriodic(
        symbol: symbol, period: period);
  }

  /// Get user's API key information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-key
  Future<Map<String, dynamic>> getApiKeyInfo() async {
    log.i('Get user API key information.');
    return await rest.getApiKeyInfo();
  }

  /// Get user's API key information periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-key
  void getApiKeyInfoPeriodic({@required Duration period}) {
    log.i('Get user API key information periodically.');
    rest.getApiKeyInfoPeriodic(period: period);
  }

  /// Get user's LCP (data refreshes once an hour).
  /// https://bybit-exchange.github.io/docs/inverse/#t-lcp
  Future<Map<String, dynamic>> getUserLCP({@required String symbol}) async {
    log.i('Get user LCP.');
    return await rest.getUserLCP(symbol: symbol);
  }

  /// Get user's LCP (data refreshes once an hour) periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-lcp
  void getUserLCPPeriodic(
      {@required String symbol, @required Duration period}) {
    log.i('Get user LCP periodically.');
    rest.getUserLCPPeriodic(symbol: symbol, period: period);
  }

  /// Get wallet balance
  /// https://bybit-exchange.github.io/docs/inverse/#t-wallet
  Future<Map<String, dynamic>> getWalletBalance({String currency}) async {
    log.i('Get wallet balance information.');
    return await rest.getWalletBalance(currency: currency);
  }

  /// Get wallet balance periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-wallet
  void getWalletBalancePeriodic({String currency, @required Duration period}) {
    log.i('Get wallet balance information periodically.');
    rest.getWalletBalancePeriodic(currency: currency, period: period);
  }

  /// Get wallet fund records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-walletrecords
  Future<Map<String, dynamic>> getWalletFundRecords(
      {String currency,
      int startTimestamp,
      int endTimestamp,
      String walletFundType,
      int page,
      int limit}) async {
    log.i('Get wallet fund records.');
    return await rest.getWalletFundRecords(
        currency: currency,
        startTimestamp: startTimestamp,
        endTimestamp: endTimestamp,
        walletFundType: walletFundType,
        page: page,
        limit: limit);
  }

  /// Get wallet fund records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-walletrecords
  void getWalletFundRecordsPeriodic(
      {String currency,
      int startTimestamp,
      int endTimestamp,
      String walletFundType,
      int page,
      int limit,
      @required Duration period}) {
    log.i('Get wallet fund records periodically.');
    rest.getWalletFundRecordsPeriodic(
        currency: currency,
        startTimestamp: startTimestamp,
        endTimestamp: endTimestamp,
        walletFundType: walletFundType,
        page: page,
        limit: limit,
        period: period);
  }

  /// Get withdrawal records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-withdrawrecords
  Future<Map<String, dynamic>> getWithdrawalRecords(
      {String currency,
      int startTimestamp,
      int endTimestamp,
      String status,
      int page,
      int limit}) async {
    log.i('Get withdrawal records.');
    return await rest.getWithdrawalRecords(
        currency: currency,
        startTimestamp: startTimestamp,
        endTimestamp: endTimestamp,
        status: status,
        page: page,
        limit: limit);
  }

  /// Get withdrawal records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-withdrawrecords
  void getWithdrawalRecordsPeriodic(
      {String currency,
      int startTimestamp,
      int endTimestamp,
      String status,
      int page,
      int limit,
      @required Duration period}) {
    log.i('Get withdrawal records periodically.');
    rest.getWithdrawalRecordsPeriodic(
        currency: currency,
        startTimestamp: startTimestamp,
        endTimestamp: endTimestamp,
        status: status,
        page: page,
        limit: limit,
        period: period);
  }

  /// Get asset exchange records.
  /// https://bybit-exchange.github.io/docs/inverse/#t-assetexchangerecords
  Future<Map<String, dynamic>> getAssetExchangeRecords(
      {String direction, int from, int limit}) async {
    log.i('Get asset exchange records.');
    return await rest.getAssetExchangeRecords(
        direction: direction, from: from, limit: limit);
  }

  /// Get asset exchange records periodically.
  /// https://bybit-exchange.github.io/docs/inverse/#t-assetexchangerecords
  void getAssetExchangeRecordsPeriodic(
      {String direction, int from, int limit, @required Duration period}) {
    log.i('Get asset exchange records periodically.');
    rest.getAssetExchangeRecordsPeriodic(
        direction: direction, from: from, limit: limit, period: period);
  }

  /// Get the server time (used for synchronization purposes for example)
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-servertime
  Future<Map<String, dynamic>> getServerTime() async {
    log.i('Get server time.');
    return await rest.getServerTime();
  }

  /// Get the server time (used for synchronization purposes for example)
  /// periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-servertime
  void getServerTimePeriodic({@required Duration period}) {
    log.i('Get server time periodically.');
    rest.getServerTimePeriodic(period: period);
  }

  /// Get Bybit OpenAPI announcements in the last 30 days in reverse order.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-announcement
  Future<Map<String, dynamic>> getAnnouncement() async {
    log.i('Get announcements.');
    return await rest.getAnnouncement();
  }

  /// Get Bybit OpenAPI announcements in the last 30 days in reverse order
  /// periodically.
  /// https://bybit-exchange.github.io/docs/inverse/?console#t-announcement
  void getAnnouncementPeriodic({@required Duration period}) {
    log.i('Get announcements periodically.');
    rest.getAnnouncementPeriodic(period: period);
  }

  /// Send ping to the WebSocket server
  void ping() {
    log.i('Send ping');
    websocket.ping();
  }

  /// Subscribe to the KLines channel. A list of valid [interval] values string
  /// is at: https://bybit-exchange.github.io/docs/inverse/#t-websocketklinev2
  void subscribeToKlines({@required String symbol, @required String interval}) {
    log.i('Subscribe to KLines with symbol: ' +
        symbol +
        ' and interval: ' +
        interval);
    state.ws.isSubscribedToKlines = true;
    if (_saveState) {
      state.ws.paramKlines.add(
          ByBitWebSocketKlinesParameters(symbol: symbol, interval: interval));
    }
    websocket.subscribeTo(topic: 'klineV2', symbol: symbol, filter: interval);
  }

  /// Fetches the orderbook with a [depth] of '25' or '200' orders per side.
  /// is at: https://bybit-exchange.github.io/docs/inverse/#t-websocketorderbook25
  void subscribeToOrderBook({@required int depth, String symbol = ''}) {
    log.i('Subscribe to orderbook with depth : ' +
        depth.toString() +
        ' for the symbol: ' +
        symbol);
    state.ws.isSubscribedToOrderBook = true;
    if (_saveState) {
      state.ws.paramOrderBook
          .add(ByBitWebSocketOrderBookParameters(depth: depth, symbol: symbol));
    }
    if (depth == 25) {
      websocket.subscribeTo(
          topic: 'orderBookL2_' + depth.toString(), symbol: symbol);
    } else if (depth == 200) {
      websocket.subscribeTo(
          topic: 'orderBook_' + depth.toString() + '.100ms', symbol: symbol);
    }
  }

  /// Get real-time trading information.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websockettrade
  void subscribeToTrades({String symbol = ''}) {
    log.i('Subscribe to trades.');
    state.ws.isSubscribedToTrades = true;
    if (_saveState) {
      state.ws.paramTrades.add(ByBitWebSocketTradesParameters(symbol: symbol));
    }
    websocket.subscribeTo(topic: 'trade', symbol: symbol);
  }

  /// Get the daily insurance fund update.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketinsurance
  void subscribeToInsurance({String currency = ''}) {
    log.i('Subscribe to insurance.');
    state.ws.isSubscribedToInsurance = true;
    if (_saveState) {
      state.ws.paramInsurance
          .add(ByBitWebSocketInsuranceParameters(currency: currency));
    }
    websocket.subscribeTo(topic: 'insurance', symbol: currency);
  }

  /// Get latest information for symbol.
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketinstrumentinfo
  void subscribeToInstrumentInfo({@required String symbol}) {
    log.i('Subscribe to the latest symbol information.');
    state.ws.isSubscribedToInstrumentInfo = true;
    if (_saveState) {
      state.ws.paramInstrumentInfo
          .add(ByBitWebSocketInstrumentInfoParameters(symbol: symbol));
    }
    websocket.subscribeTo(topic: 'instrument_info.100ms', symbol: symbol);
  }

  /// Subscribe to the position channel. You need to have a valid api-key
  /// in order to receive a valid response from the server
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketposition
  void subscribeToPosition() {
    log.i('Subscribe to position');
    state.ws.isSubscribedToPosition = true;
    websocket.subscribeTo(topic: 'position');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketexecution
  void subscribeToExecution() {
    log.i('Subscribe to execution');
    state.ws.isSubscribedToExecution = true;
    websocket.subscribeTo(topic: 'execution');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketorder
  void subscribeToOrder() {
    log.i('Subscribe to order');
    state.ws.isSubscribedToOrder = true;
    websocket.subscribeTo(topic: 'order');
  }

  /// Private topic to subscribe to with a valid api-Key. See
  /// https://bybit-exchange.github.io/docs/inverse/#t-websocketstoporder
  void subscribeToStopOrder() {
    log.i('Subscribe to stop_order');
    state.ws.isSubscribedToStopOrder = true;
    websocket.subscribeTo(topic: 'stop_order');
  }
}
