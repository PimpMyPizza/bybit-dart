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

ByBit is a [Dart](https://dart.dev/) library for an easy communication with the [bybit](https://www.bybit.com/) exchange platform [API](https://bybit-exchange.github.io/docs/inverse/#t-introduction). This package allows to make simple API call over simple HTTP-requests (REST) or with WebSocket subscriptions.

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
// bybit2lol.getInstance(...) doesn't change the key and timeout, since it was
// Invoked after the first call of getInstance(...)
ByBit bybit2lol = ByBit.getInstance(key: 'OtHeRkEyLoLoLoL', restTimeout: 1000);
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

See [the file example/lib/main.dart](https://github.com/PimpMyPizza/bybit-dart/blob/main/example/lib/main.dart) for a concrete example of WebSocket (stream) and Future (http) communication. [The file example/lib/main_flutter.dart](https://github.com/PimpMyPizza/bybit-dart/blob/main/example/lib/main_flutter.dart) shows an example using flutter Widgets.

## List of functions

See [the documentation](https://pub.dev/documentation/bybit/latest/bybit/ByBit-class.html) for the latest avaiable functions. The general rule is that the HTTP requests (REST) returns a `Future<String>`, and the String can actually be parsed as a JSON object with `jsonDecode(...)` (in later releases, the output will be better formated). The data coming from the WebSocket can be read with a StreamBuilder for example (as shown in the [example file](https://github.com/PimpMyPizza/bybit-dart/blob/main/example/lib/main.dart)).