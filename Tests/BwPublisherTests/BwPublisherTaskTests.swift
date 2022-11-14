@testable import BwPublisher
import XCTest

final class BwPublisherTaskTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPTask1() throws {
        let task0 = Publisher<Void>.firstTask { task in
            task.signal(())
        }

        let task1: Publisher<Int> = task0.wait { task, result in
            print("*** 1.result = \(String(describing: result))")
            task.signal(1)
        }
        let task2: Publisher<String> = task1.wait { task, result in
            print("*** 2.result = \(result)")
            task.signal("")
        }
        let _: Publisher<Bool> = task2.wait { task, result in
            print("*** 3.result = \(result)")
            task.signal(false)
        }
    }

    func testPTask2() throws {
        let task1 = Publisher<Int>()
        let task2 = Publisher<String>()
        let task3 = Publisher<Bool>()

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

    func testPTaskBasic() {
        let expectation1 = XCTestExpectation(description: "expectation1")

        let task0 = Publisher<Void>.firstTask { task in
            print("*** 0")
            usleep(500_000)
            task.signal(())
        }

        let task1: Publisher<Int> = task0.wait { task, result in
            print("*** 1.result = \(result)")
            usleep(500_000)
            task.signal(1)
        }

        let task2: Publisher<String> = task1.wait { task, result in
            print("*** 2.result = \(result)")
            usleep(500_000)
            task.signal("*")
        }

        let _: Publisher<Bool> = task2.wait { task, result in
            print("*** 3.result = \(result)")
            task.signal(false)
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 5.0)
    }

    var bag = SubscriptionBag()

    /// 順番にタスクを実行するテスト。クラスが終了した後のテストなどが必要か🤔
    func testPTaskCascaded() {
        //        let expectation1 = XCTestExpectation(description: "expectation1")
        //        let expectation2 = XCTestExpectation(description: "expectation2")
        //        let expectation3 = XCTestExpectation(description: "expectation3")
        //
        //        let task1 = Publisher<Int>()
        //        let task2 = Publisher<String>()
        //        let task3 = Publisher<Bool>()
        //
        //        task1
        //            .andThen(task2) { intValue in
        //                print("task1 completed with \(intValue)")
        //
        //                expectation1.fulfill()
        //            }
        //            .andThen(task3) { stringValue in
        //                print("task2 completed with \(stringValue)")
        //
        //                expectation2.fulfill()
        //            }
        //            .sink(self) { boolValue in
        //                print("task3 completed with \(boolValue)")
        //
        //                expectation3.fulfill()
        //            }
        //            .unsubscribed(by: bag)
        //
        //        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
        //            task1.signal(5)
        //        }
        //
        //        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        //            task2.signal("hello")
        //        }
        //
        //        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
        //            task3.signal(true)
        //        }
        //
        //        wait(for: [expectation1, expectation2, expectation3], timeout: 5.0)
    }
}
