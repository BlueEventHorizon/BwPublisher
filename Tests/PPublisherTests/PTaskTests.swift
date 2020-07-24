//
//  PTaskTests.swift
//  PPublisher
//
//  Created by k_terada on 2020/07/23.
//

import XCTest
@testable import PPublisher

class PTaskTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPTask1() throws {
        let task0 = PTaskStart.firstTask { task in
            task.signal(())
        }

        let task1: PTask<Int> = task0.wait { task, result in
            print("*** 1.result = \(String(describing: result))")
            task.signal(1)
        }
        let task2: PTask<String> = task1.wait { task, result in
            print("*** 2.result = \(result)")
            task.signal("")
        }
        let _: PTask<Bool> = task2.wait { task, result in
            print("*** 3.result = \(result)")
            task.signal(false)
        }
    }

    func testPTask2() throws {
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
