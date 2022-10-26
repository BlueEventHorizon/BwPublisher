# BwPublisher

[![Release](https://img.shields.io/github/v/release/BlueEventHorizon/BwPublisher)](https://github.com/BlueEventHorizon/BwPublisher/releases/latest)
[![License](https://img.shields.io/github/license/BlueEventHorizon/BwPublisher)](https://github.com/BlueEventHorizon/BwPublisher/blob/main/LICENSE)
[![Twitter](https://img.shields.io/twitter/follow/beowulf_tech?style=social)](https://twitter.com/beowulf_tech)

## BwPublisher is the light weight publish/subscribe library

This library can be used for the purpose of operating loosely coupled between software layers like RxSwift and Combine Framework.
It's very lightweight and consumes little memory, as only the minimum amount of observing functionality is implemented.
It is suitable for use in apps with limited memory, such as App Clips introduced from iOS14.

## Usage

it is very easy to use BwPublisher

### Publisher

```swift

class Hoge {
    var publisher = Publisher<String>()
    
    func action() {
        publisher.send("Hoge Updated")
    }
}

```

### Subscriber

```swift

class Fuga {

    let hoge = Hoge()
    var bag = SubscriptionBag()
    
    ... invoke configure() at somwhere ...
    
    func configure() {
        hoge.publisher
            .sink(self) { [weak self] message in
                print(message)
            }
            .unsubscribed(by: bag)
    }
}

```
