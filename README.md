[![BSD License][license-badge]][license-link]
[![PRs Welcome][prs-badge]][prs-link]
[![Watch on GitHub][github-watch-badge]][github-watch-link]
[![Star on GitHub][github-star-badge]][github-star-link]
[![Watch on GitHub][github-forks-badge]][github-forks-link]

[license-badge]: https://img.shields.io/github/license/PimpMyPizza/bybit-dart.svg?style=for-the-badge
[license-link]: https://github.com/PimpMyPizza/bybit-dart/blob/main/LICENSE
[prs-badge]: https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge
[prs-link]: https://github.com/PimpMyPizza/bybit-dart/issues

[github-watch-badge]: https://img.shields.io/github/watchers/PimpMyPizza/bybit-dart.svg?style=for-the-badge&logo=github&logoColor=ffffff
[github-watch-link]: https://github.com/PimpMyPizza/bybit-dart/watchers
[github-star-badge]: https://img.shields.io/github/stars/PimpMyPizza/bybit-dart.svg?style=for-the-badge&logo=github&logoColor=ffffff
[github-star-link]: https://github.com/PimpMyPizza/bybit-dart/stargazers
[github-forks-badge]: https://img.shields.io/github/forks/PimpMyPizza/bybit-dart.svg?style=for-the-badge&logo=github&logoColor=ffffff
[github-forks-link]: https://github.com/PimpMyPizza/bybit-dart/network/members


# ByBit

ByBit is a [Dart](https://dart.dev/) package for a communication with the [bybit](https://www.bybit.com/) exchange platform [API](https://bybit-exchange.github.io/docs/inverse/#t-introduction)

## Table of content
- [How to use](#How-to-use)
- [Example](#Example)
- [List of functions](#List-of-functions)

## How to use

### Import the library

``` Dart
import 'package:bybit/bybit.dart';
```

### Create a ByBit instance

Use the `getInstance` function to create an instance of ByBit. Note that the first parameters that you give to the function can't be changed after the first call of getInstance

``` Dart
ByBit bybit = ByBit.getInstance(
        key: 'yOuRsUpErKey',
        password: 'yOuRsUpErPaSsWoRd',
        logLevel: 'INFO',
        restUrl: 'https://api.bybit.com',
        restTimeout: 3000,
        websocketUrl: 'wss://stream.bytick.com/realtime',
        websocketTimeout: 2000);
// otherBybitInstance will have the same parameters as bybit. Doesn't matter what parameters you give here.
ByBit otherBybitInstance = ByBit.getInstance(key: 'OtHeRkEyLoLoLoL', restTimeout: 1000);
```

### Connect

If you want to use WebSocket streams. If you just want to make REST API calls, no need to connect
``` Dart
bybit.connect();
```

### Subscribe to topics and read stream if you want

Note that some topics are public and doesn't require a valid api-key and password. If you only want to use public topics, you don't need to pass the `key` and `password` to the `ByBit.getInstance(...)` function.

Note also the `websocket.websocket`
``` Dart
// ...
bybit.subscribeToKlines(symbol: 'ETHUSD', interval: '1');
bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
bybit.subscribeToOrderBook(depth: 25);
// ...
StreamBuilder(
    stream: bybit.websocket.websocket.stream,
    builder: (context, bybitResponse) {
          print('From WebSocket: ' + bybitResponse.data.toString());
          //...
    }
),
//...
```

### Make some HTTP request if you want

``` Dart
// ...
FutureBuilder(
    future: bybit.getKLine(symbol: 'BTCUSD', from: 1581231260, interval: 'D'),
    builder: (context, bybitResponse) {
        // Handle the bybit response here
        if (bybitResponse.hasData && bybitResponse.data != null) {
          print('From REST: ' + bybitResponse.data.toString());
          //...
```

## Example

See [the file example/lib/main.dart](https://github.com/PimpMyPizza/bybit-dart/blob/main/example/lib/main.dart) for a concrete example of WebSocket (stream) and Future (http) communication

## List of functions
- Initialization:
    * [getInstance](#getInstance)
    * [connect](#connect)
    * [disconnect](#disconnect)
- Market data endpoints:
    * [getOrderBook](#getOrderBook)
    * [getKLine](#getKLine)
    * [getTickers](#getTickers)
    * [getTradingRecords](#getTradingRecords)
    * [getSymbolsInfo](#getSymbolsInfo)
    * [getLiquidatedOrders](#getLiquidatedOrders)
- Account data endpoints:
    - Active orders:
        * [placeActiveOrder](#placeActiveOrder)
        * [updateActiveOrder](#updateActiveOrder)
        * [getActiveOrder](#getActiveOrder)
        * [getRealTimeActiveOrder](#getRealTimeActiveOrder)
        * [cancelActiveOrder](#cancelActiveOrder)
        * [cancelAllActiveOrders](#cancelAllActiveOrders)
    - Conditional orders:
        * [placeConditionalOrder](#placeConditionalOrder)
        * [updateConditionalOrder](#updateConditionalOrder)
        * [getConditionalOrder](#getConditionalOrder)
        * [getConditionalOrders](#getConditionalOrders)
        * [cancelConditionalOrder](#cancelConditionalOrder)
        * [cancelAllConditionalOrders](#cancelAllConditionalOrders)
    - Position:
        * [getPosition](#getPosition)
        * [setMargin](#setMargin)
        * [setTradingStop](#setTradingStop)
        * [setLeverage](#setLeverage)
        * [getUserTradingRecords](#getUserTradingRecords)
        * [getUserClosedProfit](#getUserClosedProfit)
    - Risk limit:
        * [getRiskLimit](#getRiskLimit)
        * [setRiskLimit](#setRiskLimit)
    - Funding:
        * [getFundingRate](#getFundingRate)
        * [getPreviousFundingFee](#getPreviousFundingFee)
        * [getPredictedFundingRateAndFundingFee](#getPredictedFundingRateAndFundingFee)
    - API key information:
        * [getApiKeyInfo](#getApiKeyInfo)
    - LCP information:
        * [getUserLCP](#getUserLCP)
    - Wallet
        * [getWalletBalance](#getWalletBalance)
        * [getWalletFundRecords](#getWalletFundRecords)
        * [getWithdrawalRecords](#getWithdrawalRecords)
        * [getAssetExchangeRecords](#getAssetExchangeRecords)
- API data endpoints:
    * [getServerTime](#getServerTime)
    * [getAnnouncement](#getAnnouncement)
- WebSocket data:
    * [ping](#ping)
    * [subscribeToKlines](#subscribeToKlines)
    * [subscribeToOrderBook](#subscribeToOrderBook)
    * [subscribeToTrades](#subscribeToTrades)
    * [subscribeToInsurance](#subscribeToInsurance)
    * [subscribeToInstrumentInfo](#subscribeToInstrumentInfo)
    * [subscribeToPosition](#subscribeToPosition)
    * [subscribeToExecution](#subscribeToExecution)
    * [subscribeToOrder](#subscribeToOrder)
    * [subscribeToStopOrder](#subscribeToStopOrder)

----------------------------------------------------------------------------------


### getInstance



### connect

  

Connect to the WebSocket server and/or the REST API server

  

### disconnect

  

Disconnect the websocket and http client

  

### getOrderBook

  

Get the orderbook.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-orderbook)

  

### getKLine

Get kline. [official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-querykline)

  

### getTickers

Get the latest information for symbol.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-latestsymbolinfo)

### getTradingRecords

Get recent trades.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-publictradingrecords)

### getSymbolsInfo

Get symbol info.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol)

  

### getLiquidatedOrders

Retrieve the liquidated orders, The query range is the last seven days of data.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-querysymbol)

  

### placeActiveOrder

Place active order

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive)

  

### getActiveOrder

Get active order

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-placeactive)

  

### cancelActiveOrder

Cancel active order. Note that either orderId or orderLinkId are required

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-cancelactive)

### cancelAllActiveOrders

Cancel all active orders that are unfilled or partially filled. Fully filled orders cannot

be cancelled.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-cancelallactive)

### updateActiveOrder

Replace order can modify/amend your active orders.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-replaceactive)

  

### getRealTimeActiveOrder

Query real-time active order information.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-queryactive)

### placeConditionalOrder

Place a market price conditional order

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-placecond)

  

### getConditionalOrders

Get user conditional order list.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-getcond)

### cancelConditionalOrder

Cancel untriggered conditional order

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-cancelcond)

  

### cancelAllConditionalOrders

Cancel all untriggered conditional orders

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-cancelallcond)

  

### updateConditionalOrder

Replace conditional order

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-replacecond)

  

### getConditionalOrder

Query conditional order

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-querycond)

### getPosition

Get user position list

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-myposition)

### setMargin

Update margin

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-changemargin)

  

### setTradingStop

Set trading-stop

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-tradingstop)

### setLeverage

Set leverage

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-setleverage)

  

### getUserTradingRecords

Get user's trading records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-usertraderecords)

### getUserClosedProfit

Get user's closed profit and loss records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-closedprofitandloss)

### getRiskLimit

Get risk limit

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-risklimit)

  

### setRiskLimit

Set risk limit

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-setrisklimit)

  

### getFundingRate

Get the last funding rate

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-fundingrate)

### getPreviousFundingFee

Get previous funding fee

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-mylastfundingfee)

### getPredictedFundingRateAndFundingFee

Get predicted funding rate and my funding fee.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-predictedfunding)

### getApiKeyInfo

Get user's API key information.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-key)

### getUserLCP

Get user's LCP (data refreshes once an hour).

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-lcp)

### getWalletBalance

Get wallet balance

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-wallet)

### getWalletFundRecords

Get wallet fund records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-walletrecords)

### getWithdrawalRecords

Get withdrawal records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-withdrawrecords)

### getAssetExchangeRecords

Get asset exchange records.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-assetexchangerecords)

### getServerTime

Get the server time (used for synchronization purposes for example)

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-servertime)


### getAnnouncement

Get Bybit OpenAPI announcements in the last 30 days in reverse order.

[official doc](https://bybit-exchange.github.io/docs/inverse/?console#t-announcement)


### ping

Send ping to the WebSocket server

  

### subscribeToKlines

Subscribe to the KLines channel. A list of valid [interval] values string

is at: [official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketklinev2)

  

### subscribeToOrderBook

Fetches the orderbook with a [depth] of '25' or '200' orders per side.

is at: [official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketorderbook25)

  

### subscribeToTrades

Get real-time trading information.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websockettrade)

  

### subscribeToInsurance

Get the daily insurance fund update.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketinsurance)

  

### subscribeToInstrumentInfo

Get latest information for symbol.

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketinstrumentinfo)

  

### subscribeToPosition

Subscribe to the position channel. You need to have a valid api-key in order to receive a valid response from the server

  

### subscribeToExecution

Private topic to subscribe to with a valid api-Key. See

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketexecution)

  

### subscribeToOrder

Private topic to subscribe to with a valid api-Key. See

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketorder)

  

### subscribeToStopOrder

Private topic to subscribe to with a valid api-Key. See

[official doc](https://bybit-exchange.github.io/docs/inverse/#t-websocketstoporder)
