//
//  PTask.swift
//  BwTools
//
//  Created by k2moons on 2018/08/20.
//  Copyright (c) 2018 k2moons. All rights reserved.
//

import Foundation

public typealias PTask = Publisher
public typealias PTaskStart = PTask<()>

public extension PTask {

    static func firstTask<Void>(completion: @escaping ((PTaskStart) -> Void)) -> PTaskStart {
        let task = PTaskStart()
        _ = completion(task)
        return task
    }

    /// 前のタスクがある場合
    ///
    /// - Parameters:
    ///   - preTask: 前のタスクのPublisher
    ///   - completion: 前のタスクが終了した時に呼び出されるクロージャ
    /// - Returns: PTask
    func wait<TaskType>(main: Bool = true, completion: @escaping ((PTask<TaskType>, ContentsType) -> Void)) -> PTask<TaskType> {
        let task = PTask<TaskType>()
        self.once(self, latest: true, main: main) { (result) in
            completion(task, result)
        }
        return task
    }

    func wait(_ subscriber: Subscriber, main: Bool = true, action: @escaping ((_ contents: ContentsType ) -> Void) ) {
        once(subscriber, latest: false, main: main, action: action)
    }

    func signal(_ contents: ContentsType) {
        publish(contents)
    }
}

// MARK: - Test

open class PublisherTest {

    public init() {
    }

    public func test() {

        let task0 = PTaskStart.firstTask { (task) in
            task.signal(())
        }

        let task1: PTask<Int> = task0.wait { (task, result) in
            print("*** 1.result = \(String(describing: result))")
            task.signal(1)
        }
        let task2: PTask<String> = task1.wait { (task, result) in
            print("*** 2.result = \(result)")
            task.signal("")
        }
        let _: PTask<Bool> = task2.wait { (task, result) in
            print("*** 3.result = \(result)")
            task.signal(false)
        }
    }

    public func test2() {
        let task1 = PTask<Int>()
        let task2 = PTask<String>()
        let task3 = PTask<Bool>()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            print("***** 1 *****")
            task1.signal(1)
        }

        task1.once(self) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                print("***** 2 *****")
                task2.signal("2")
            }
        }

        task2.once(self) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                print("***** 3 *****")
                task3.signal(true)
            }
        }

        task3.once(self) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                print("***** 4 *****")
            }
        }
    }
}
