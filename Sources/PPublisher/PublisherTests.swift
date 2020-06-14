//
//  PublisherTests.swift
//  PublisherTests
//
//  Created by k_terada on 2020/05/31.
//  Copyright © 2020 k2moons. All rights reserved.
//

import XCTest
import Logger
import PPublisherTestApp

class PublisherTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPublisherWithSingleton() throws {

        let expectation1 = XCTestExpectation(description: "expectation1")
        var subscriber: Subscriber?

        class SingletonPublisher {
            static let shared = SingletonPublisher()
            private init() {
                run()
            }

            var counter: Int = 0
            var value = Publisher<Int>()

            func run() {
                DispatchQueue.global(qos: .userInitiated).async {
                    while true {
                        usleep(100_000)
                        self.value.publish(self.counter)
                        self.counter += 1
                    }
                }
            }

            deinit {
                log.deinit(self)
            }
        }

        class Subscriber {
            var bag: SubscribeBag = SubscribeBag()
            let publisher = SingletonPublisher.shared

            init() {
                configure()
            }

            func configure() {
                publisher.value.subscribe(self) { value in
                    log.info("value = \(value)")
                }.unsubscribed(by: bag)
            }

            deinit {
                log.deinit(self)
            }
        }

        func makeSubscriberScope() {
            DispatchQueue.global(qos: .background).async {

                usleep(1000_000)

                log.info("subscriber will nil")
                subscriber = nil
                log.info("subscriber did nil")

                expectation1.fulfill()
            }
        }

        subscriber = Subscriber()
        makeSubscriberScope()

        wait(for: [expectation1], timeout: 10.0)

        usleep(1000_000)

        log.info("Exit \(#function)")
    }

    func testPublisher() {

        let expectation1 = XCTestExpectation(description: "expectation1")
        let expectation2 = XCTestExpectation(description: "expectation2")
        let expectation3 = XCTestExpectation(description: "expectation3")
        let expectation4 = XCTestExpectation(description: "expectation4")

        let bag: SubscribeBag = SubscribeBag()

        let publisher = Publisher<String>()
        publisher.once(self, action: {r in print("\(r)-1")
            expectation1.fulfill()
        })

        publisher.subscribe(self, action: {r in print("\(r)-2")
            expectation2.fulfill()
        }).unsubscribed(by: bag)

        publisher.once(self, action: {r in print("\(r)-3")
            expectation3.fulfill()
        })

        publisher.subscribe(self, action: {r in print("\(r)-4")
            expectation4.fulfill()
        }).unsubscribed(by: bag)

        publisher.publish("first")
        publisher.publish("second")
        publisher.unsubscribe(by: self)
        publisher.publish("third")

        wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 1.0)
    }

    func testPTaskBasic() {

        let expectation1 = XCTestExpectation(description: "expectation1")

        let task0 = PTaskStart.firstTask { (task) in
            print("*** 0")
            usleep(500000)
            task.signal(())
        }

        let task1: PTask<Int> = task0.wait { (task, result) in
            print("*** 1.result = \(result)")
            usleep(500000)
            task.signal(1)
        }
        let task2: PTask<String> = task1.wait { (task, result) in
            print("*** 2.result = \(result)")
            usleep(500000)
            task.signal("*")
        }
        let _: PTask<Bool> = task2.wait { (task, result) in
            print("*** 3.result = \(result)")
            task.signal(false)
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 5.0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}