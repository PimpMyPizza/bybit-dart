[![pub package][pub]][pub-link]
[![BSD License][license-badge]][license-link]
[![PRs Welcome][prs-badge]][prs-link]
[![Last changes][github-changes-badge]][github-changes-link]
[![CI][CI-badge]][CI-link]


[pub]: https://img.shields.io/pub/v/bybit.svg?style=for-the-badge&logo=dart
[pub-link]: https://pub.dev/packages/bybit
[license-badge]: https://img.shields.io/github/license/PimpMyPizza/bybit-dart.svg?style=for-the-badge
[license-link]: https://github.com/PimpMyPizza/bybit-dart/blob/main/LICENSE
[prs-badge]: https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge
[prs-link]: https://github.com/PimpMyPizza/bybit-dart/issues
[github-changes-badge]: https://img.shields.io/github/last-commit/PimpMyPizza/bybit-dart?style=for-the-badge&logo=git&logoColor=white
[github-changes-link]: https://github.com/PimpMyPizza/bybit-dart/commits/master
[CI-badge]: https://img.shields.io/github/workflow/status/PimpMyPizza/bybit-dart/Dart?logo=github-actions&style=for-the-badge
[CI-link]: https://github.com/PimpMyPizza/bybit-dart/actions


# ByBit

ByBit is a [Dart](https://dart.dev/) library for an easy communication with the [bybit](https://www.bybit.com/) exchange platform [API](https://bybit-exchange.github.io/docs/inverse/#t-introduction). This package allows to make simple REST API calls or to subscribe to several WebSockets channels topics.

## How to use it

### Create a ByBit instance

Note that all the parameters are optional, but you need a valid key and password to access private topics from bybit. You can create your own api-key [on the bybit website](https://www.bybit.com/app/user/api-management).

``` Dart
var bybit = ByBit(
        key: 'yOuRsUpErKey',
        password: 'yOuRsUpErPaSsWoRd',
        logLevel: 'INFO',
        restUrl: 'https://api.bybit.com',
        websocketUrl: 'wss://stream.bytick.com/realtime',
        timeout: 60); // in seconds
```

### Connect to the servers

``` Dart
bybit.connect();
```

### Add periodic REST API call if you want to

Sometimes, you want to get information from the API every x period of time. That's why this library allows one to set which REST API call has to be done periodically, and all the responses from the server are merged into one single stream. Please note [the limit of API calls](https://bybit-exchange.github.io/docs/inverse/#t-ratelimits).

```Dart
bybit.getServerTimePeriodic(period: Duration(seconds: 5));
bybit.getAnnouncementPeriodic(period: Duration(seconds: 5));
bybit.getOpenInterestPeriodic(
    symbol: 'ETHUSD',
    interval: '15min',
    period: Duration(seconds: 2),
    limit: 3);
```


### Subscribe to WebSocket topics

``` Dart
// ...
bybit.subscribeToKlines(symbol: 'ETHUSD', interval: '1');
bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
bybit.subscribeToOrderBook(depth: 25);
```

### Read the ByBit stream and handle the server response

Note that the `bybit.stream` streams all the data from the WebSockets and periodic REST API calls.

```Dart
StreamBuilder(
    stream: bybit.stream,
    builder: (context, bybitResponse) {
          print('From WebSocket: ' + bybitResponse.data.toString());
          //...
    }
),
//...
```

### You can also make single REST API calls

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

See [the file main.dart](https://github.com/PimpMyPizza/bybit-dart/blob/main/example/lib/main.dart) in the `example/lib/` directory for a simple Dart example. Also, the files [main_flutter_stream.dart](https://github.com/PimpMyPizza/bybit-dart/blob/main/example/lib/main_flutter_stream.dart) and [main_flutter_future.dart](https://github.com/PimpMyPizza/bybit-dart/blob/main/example/lib/main_flutter_future.dart) show examples using `FutureBuilder` and `StreamBuilder`.

## List of functions

See [the documentation](https://pub.dev/documentation/bybit/latest/bybit/ByBit-class.html) for the latest avaiable functions.
