//
//  Publisher.swift
//  BwTools
//
//  Created by k2moons on 2018/08/20.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import Foundation

extension Publisher {
    // 最初のタスクのPublisherを返す
    public static func firstTask<Void>(completion: @escaping ((Publisher<Void>) -> Void)) -> Publisher<Void> {
        let task = Publisher<Void>()
        _ = completion(task)
        return task
    }

    /// 前のタスクをwaitし、次のタスクのPublisherを返す
    /// - Parameters:
    ///   - main: メインスレッドで受けるかどうか
    ///   - completion: 完了クロージャ
    /// - Returns: 次のタスク
    public func wait<T>(main: Bool = true, completion: @escaping ((Publisher<T>, ContentsType) -> Void)) -> Publisher<T> {
        let task = Publisher<T>()
        self.once(self, latest: true, main: main) { result in
            completion(task, result)
        }
        return task
    }

    public func wait(_ subscriber: Subscriber, main: Bool = true, action: @escaping ((_ contents: ContentsType) -> Void)) {
        once(subscriber, latest: false, main: main, action: action)
    }

    public func signal(_ contents: ContentsType) {
        publish(contents)
    }
}
