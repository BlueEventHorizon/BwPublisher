//
//  Publisher.swift
//  Publisher
//
//  Created by k2moons on 2018/07/28.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import Foundation
import Logger

// MARK: - Unsubscribable

/// A protocol with a method for canceling subscribe all at once
private protocol Unsubscribable {
    func unsubscribe()
    func unsubscribe(_ idetifier: SubscribeBagIdentifier)
}

/// Because this is just an identifier, AnyObject can be
public typealias Subscriber = AnyObject
public typealias SubscribeBagIdentifier = Int

// MARK: - SubscribeBag

/// Class for canceling subscribe when subscribed instance is destroyed

public final class SubscribeBag {

    private var unsubscribables = [Unsubscribable]()
    private static var globalIdentifier: SubscribeBagIdentifier = 0
    private(set) var idetifier: SubscribeBagIdentifier

    public init() {
        idetifier = SubscribeBag.globalIdentifier
        SubscribeBag.globalIdentifier += 1
    }

    fileprivate func set(_ subscriberInfo: Unsubscribable) -> SubscribeBagIdentifier {
        unsubscribables.append(subscriberInfo)
        return idetifier
    }

    deinit {
        log.deinit(self)
        for unsubscribable in unsubscribables {
            unsubscribable.unsubscribe(idetifier)
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

    public class Subscription: Unsubscribable {

        fileprivate var action: ((_ result: ContentsType ) -> Void)
        fileprivate weak var subscriber: Subscriber?
        fileprivate var once: Bool = false
        fileprivate var main: Bool = true

        private var publisher: Publisher<ContentsType>?
        private(set) var identifier: SubscribeBagIdentifier = -1

        required public init(

            _ subscriber: Subscriber,
            publisher: Publisher<ContentsType>,
            once: Bool, main: Bool,
            action: @escaping ((ContentsType) -> Void)

        ) {
            self.subscriber = subscriber
            self.once = once
            self.main = main
            self.action = action
            self.publisher = publisher
        }

        public func unsubscribed(by unsubscribeBag: SubscribeBag) {
            identifier = unsubscribeBag.set(self)
        }

        // 指定されたSubscriberによってsubscribeされているものをunsubscribeする
        fileprivate func unsubscribe() {
            if let _observer = subscriber {
                self.publisher?.unsubscribe(by: _observer)
            }
        }

        // 指定されたidentifierによってunsubscribeする
        fileprivate func unsubscribe(_ identifier: SubscribeBagIdentifier) {
            self.publisher?.unsubscribe(by: identifier)
        }

        deinit {
            log.deinit(self)
        }
    }

    // ---------------------------------------------------------------

    private var subscriptions: [Subscription] = []
    private var latestContents: ContentsType?

    public init(_ contents: ContentsType? = nil) {
        latestContents = contents
    }

    // ---------------------------------------------------------------
    /// subscribe
    ///
    /// - Parameters:
    ///   - subscriber: BwObserver that observe this Publisher. This is just identifier of subscriber.
    ///   - once: subscribe once
    ///   - latest: immediately return contens, if it already exists.
    ///   - main: if true, action executed in main thread
    ///   - action: closure that is invoked when contents are published
    /// - Returns: Subscription?

    @discardableResult
    public func subscribe(

        _ subscriber: Subscriber,
        latest: Bool = false,
        main: Bool = true,
        action: @escaping ((_ contents: ContentsType ) -> Void)

    ) -> Subscription {

        if latest, let _latestContents = latestContents {
            if main {
                DispatchQueue.main.async {
                    action(_latestContents)
                }
            } else {
                DispatchQueue.global().async {
                    action(_latestContents)
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
        action: @escaping ((_ contents: ContentsType ) -> Void)

    ) {

        if latest, let _latestContents = latestContents {
            if main {
                DispatchQueue.main.async {
                    action(_latestContents)
                }
            } else {
                DispatchQueue.global().async {
                    action(_latestContents)
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

    public func publish(_ contents: ContentsType) {

        latestContents = contents

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
        subscriptions = subscriptions.filter({ !$0.once })
    }

    // Subscriberを渡してsubscriptionを終了する
    //
    public func unsubscribe(by subscriber: Subscriber) {
        subscriptions = subscriptions.filter({ !($0.subscriber === subscriber) })
    }

    // SubscribeBagから、Subscriptionを介して呼び出される。SubscribeBag毎に割り振られたidentifierでsubscriptionを終了する
    //
    fileprivate func unsubscribe(by identifier: SubscribeBagIdentifier) {
        subscriptions = subscriptions.filter({ !($0.identifier == identifier) })
    }
}
