[![pub package][pub]][pub-link]
[![BSD License][license-badge]][license-link]
[![PRs Welcome][prs-badge]][prs-link]
[![Watch on GitHub][github-watch-badge]][github-watch-link]
[![Star on GitHub][github-star-badge]][github-star-link]

[pub]: https://img.shields.io/pub/v/bybit.svg?style=for-the-badge
[pub-link]: https://pub.dev/packages/bybit
[license-badge]: https://img.shields.io/github/license/PimpMyPizza/bybit-dart.svg?style=for-the-badge
[license-link]: https://github.com/PimpMyPizza/bybit-dart/blob/main/LICENSE
[prs-badge]: https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge
[prs-link]: https://github.com/PimpMyPizza/bybit-dart/issues

[github-watch-badge]: https://img.shields.io/github/watchers/PimpMyPizza/bybit-dart.svg?style=for-the-badge&logo=github&logoColor=ffffff
[github-watch-link]: https://github.com/PimpMyPizza/bybit-dart/watchers
[github-star-badge]: https://img.shields.io/github/stars/PimpMyPizza/bybit-dart.svg?style=for-the-badge&logo=github&logoColor=ffffff
[github-star-link]: https://github.com/PimpMyPizza/bybit-dart/stargazers


# ByBit

ByBit is a [Dart](https://dart.dev/) library for an easy communication with the [bybit](https://www.bybit.com/) exchange platform [API](https://bybit-exchange.github.io/docs/inverse/#t-introduction). This package allows to make simple REST API calls or to subscribe to several WebSockets channels topics.

## How to use

### Create a ByBit instance

Note that all the parameters are optional, but you need a valid key and password to access private topics from bybit. You can create your own api-key [on the bybit website](https://www.bybit.com/app/user/api-management)

``` Dart
var bybit = ByBit(
        key: 'yOuRsUpErKey',
        password: 'yOuRsUpErPaSsWoRd',
        logLevel: 'INFO',
        restUrl: 'https://api.bybit.com',
        restTimeout: 3000,
        websocketUrl: 'wss://stream.bytick.com/realtime',
        websocketTimeout: 2000);
```

### Connect to the server

``` Dart
bybit.connect();
```

### Subscribe to topics and read the websocket stream...

``` Dart
// ...
bybit.subscribeToKlines(symbol: 'ETHUSD', interval: '1');
bybit.subscribeToKlines(symbol: 'BTCUSD', interval: 'D');
bybit.subscribeToOrderBook(depth: 25);
// ...
StreamBuilder(
    stream: bybit.websocket.stream,
    builder: (context, bybitResponse) {
          print('From WebSocket: ' + bybitResponse.data.toString());
          //...
    }
),
//...
```

### ... and/or make some REST API calls

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
