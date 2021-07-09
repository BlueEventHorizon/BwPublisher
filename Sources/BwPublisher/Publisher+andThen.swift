//
//  Publisher+andThen.swift
//  BwTools
//
//  Created by k2moons on 2021/01/10.
//  Copyright © 2021 beowulf-tech. All rights reserved.
//

import Foundation

extension Publisher {
    // ⚠️未完成
    public func andThen<T>(_ nextTask: Publisher<T>, completion: @escaping ((Publisher<T>, ContentsType) -> Void)) -> Publisher<T> {
        self.subscribe(self) { result in
            completion(nextTask, result)
        }
        return nextTask
    }
}
