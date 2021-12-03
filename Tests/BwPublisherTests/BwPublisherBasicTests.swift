@testable import BwPublisher
import XCTest

final class BwPublisherBasicTests: XCTestCase {
    public func test() {
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

    public func test2() {
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
}
