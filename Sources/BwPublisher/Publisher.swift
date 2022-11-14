//
//  Publisher.swift
//  BwTools
//
//  Created by k2moons on 2018/07/28.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import Foundation

// swiftlint:disable strict_fileprivate

// MARK: - UnsubscribeProtocol

/// A protocol with a method for canceling subscribe all at once
private protocol UnsubscribeProtocol {
    func unsubscribe()
    func unsubscribe(_ identifier: SubscribeBagIdentifier)
}

/// Because this is just an identifier, AnyObject can be
public typealias Subscriber = AnyObject

typealias SubscribeBagIdentifier = Int

// MARK: - SubscriptionBag

/// Class for canceling subscribe when subscribed instance is destroyed
public final class SubscriptionBag {
    private var subscribers = [UnsubscribeProtocol]()
    private static var globalIdentifier: SubscribeBagIdentifier = 0
    private(set) var identifier: SubscribeBagIdentifier

    public init() {
        identifier = SubscriptionBag.globalIdentifier
        SubscriptionBag.globalIdentifier += 1
    }

    fileprivate func set(_ subscriberInfo: UnsubscribeProtocol) -> SubscribeBagIdentifier {
        subscribers.append(subscriberInfo)
        return identifier
    }

    deinit {
        for subscriber in subscribers {
            subscriber.unsubscribe(identifier)
        }
    }
}

// MARK: - Publisher

// Publisher
//
//
public final class Publisher<ContentsType> {
    // ---------------------------------------------------------------
    // subscribe()される時にSubscriberの情報を格納して、Publisherに保持される。
    // またsubscribe()の戻り値となるので、SubscribeBagに渡すことで自動削除できるようになる
    public class Subscription: UnsubscribeProtocol {
        fileprivate var action: (_ result: ContentsType) -> Void
        fileprivate weak var subscriber: Subscriber?
        fileprivate var once: Bool = false
        fileprivate var main: Bool = true

        private var publisher: Publisher<ContentsType>?
        private(set) var identifier: SubscribeBagIdentifier = -1
        private let semaphore = DispatchSemaphore(value: 1)

        public required init(
            _ subscriber: Subscriber,
            publisher: Publisher<ContentsType>,
            once: Bool,
            main: Bool,
            action: @escaping ((ContentsType) -> Void)
        ) {
            self.subscriber = subscriber
            self.once = once
            self.main = main
            self.action = action
            self.publisher = publisher
        }

        public func unsubscribed(by unsubscribeBag: SubscriptionBag) {
            semaphore.wait()
            defer {
                semaphore.signal()
            }

            identifier = unsubscribeBag.set(self)
        }

        // 指定されたSubscriberによってsubscribeされているものをunsubscribeする
        fileprivate func unsubscribe() {
            semaphore.wait()
            defer {
                semaphore.signal()
            }

            if let observer = subscriber {
                publisher?.unsubscribe(by: observer)
            }
        }

        // 指定されたidentifierによってunsubscribeする
        fileprivate func unsubscribe(_ identifier: SubscribeBagIdentifier) {
            semaphore.wait()
            defer {
                semaphore.signal()
            }

            publisher?.unsubscribe(by: identifier)
        }
    }

    // ---------------------------------------------------------------

    private var subscriptions: [Subscription] = []
    private var latestContents: ContentsType?
    private let semaphore = DispatchSemaphore(value: 1)

    public var value: ContentsType? {
        latestContents
    }

    public init(_ contents: ContentsType? = nil) {
        latestContents = contents
    }

    // ---------------------------------------------------------------
    /// subscribe
    ///
    /// - Parameters:
    ///   - subscriber: BwObserver that observe this Publisher. This is just identifier of subscriber.
    ///   - once: subscribe once
    ///   - latest: immediately return contents, if it already exists.
    ///   - main: if true, action executed in main thread
    ///   - action: closure that is invoked when contents are published
    /// - Returns: Subscription?
    @discardableResult
    public func sink(
        _ subscriber: Subscriber,
        latest: Bool = false,
        main: Bool = true,
        action: @escaping ((_ contents: ContentsType) -> Void)
    ) -> Subscription {
        semaphore.wait()
        defer {
            semaphore.signal()
        }

        if latest, let latestContents = latestContents {
            if main {
                DispatchQueue.main.async {
                    action(latestContents)
                }
            } else {
                DispatchQueue.global().async {
                    action(latestContents)
                }
            }
        }

        let subscriberInfo = Subscription(subscriber, publisher: self, once: false, main: main, action: action)
        subscriptions.append(subscriberInfo)

        return subscriberInfo
    }

    // ---------------------------------------------------------------

    public func once(
        _ subscriber: Subscriber,
        latest: Bool = false,
        main: Bool = true,
        action: @escaping ((_ contents: ContentsType) -> Void)
    ) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }

        if latest, let latestContents = latestContents {
            if main {
                DispatchQueue.main.async {
                    action(latestContents)
                }
            } else {
                DispatchQueue.global().async {
                    action(latestContents)
                }
            }
            return
        }

        let subscriberInfo = Subscription(subscriber, publisher: self, once: true, main: main, action: action)
        subscriptions.append(subscriberInfo)
    }

    // ---------------------------------------------------------------
    /// Execute action closures
    ///
    /// - Parameter contents: Contents to be published to subscribers(observers)

    public func send(_ contents: ContentsType) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }

        latestContents = contents

        // Subscriberはnilの場合は削除
        unsubscribeNoSubscriber()

        for subscriberInfo in subscriptions {
            if subscriberInfo.main {
                DispatchQueue.main.async {
                    subscriberInfo.action(contents)
                }
            } else {
                DispatchQueue.global().async {
                    subscriberInfo.action(contents)
                }
            }
        }

        // １度だけコンテンツ取得の場合は、ここで終了
        subscriptions = subscriptions.filter { !$0.once }
    }

    // Subscriberを渡してsubscriptionを終了する
    public func unsubscribe(by subscriber: Subscriber) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }

        subscriptions = subscriptions.filter { !($0.subscriber === subscriber) }
    }

    // SubscribeBagから、Subscriptionを介して呼び出される。SubscribeBag毎に割り振られたidentifierでsubscriptionを終了する
    fileprivate func unsubscribe(by identifier: SubscribeBagIdentifier) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }

        subscriptions = subscriptions.filter { !($0.identifier == identifier) }
    }
    
    // MARK: - private

    // Subscriberはnilの場合は削除
    private func unsubscribeNoSubscriber() {
        subscriptions = subscriptions.filter { $0.subscriber != nil }
    }
}

