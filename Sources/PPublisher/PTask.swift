//
//  PTask.swift
//  PPublisher
//
//  Created by k2moons on 2018/08/20.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import Foundation

public typealias PTask = Publisher
public typealias PTaskStart = PTask<Void>

public extension PTask {
    static func firstTask<Void>(completion: @escaping ((PTaskStart) -> Void)) -> PTaskStart {
        let task = PTaskStart()
        _ = completion(task)
        return task
    }

    func wait<TaskType>(main: Bool = true, completion: @escaping ((PTask<TaskType>, ContentsType) -> Void)) -> PTask<TaskType> {
        let task = PTask<TaskType>()
        self.once(self, latest: true, main: main) { result in
            completion(task, result)
        }
        return task
    }

    func wait(_ subscriber: Subscriber, main: Bool = true, action: @escaping ((_ contents: ContentsType) -> Void)) {
        once(subscriber, latest: false, main: main, action: action)
    }

    func signal(_ contents: ContentsType) {
        publish(contents)
    }
}
