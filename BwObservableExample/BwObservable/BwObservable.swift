//
//  BwObservable.swift
//  BwFramework
//
//  Created by Katsuhiko Terada on 2018/07/28.
//  Copyright (c) 2018 Katsuhiko Terada. All rights reserved.
//

import Foundation

// =============================================================================
// MARK: - BwDisposeBag
// =============================================================================

/// Because this is just an identifier, AnyObject can be
public typealias BwObserver = AnyObject

/// Class for canceling subscribe when subscribed instance is destroyed
public final class BwDisposeBag {
    private var disposables = [Disposable]()
    public init() {
    }
    fileprivate func set(_ observerInfo: Disposable) {
        //disposables.append(observerInfo)
    }
    deinit {
        for disposable in disposables {
            disposable.dispose()
        }
    }
}

// =============================================================================
// MARK: - BwObservable
// =============================================================================

//var observables = [Any] ()

/// A protocol with a method for canceling subscribe all at once
private protocol Disposable {
    func dispose()
}

/// A class that can be observed to return a specific results by closure
public final class BwObservable<ContentsType> {
    // **********************************************
    /// Class for returning observing results
    public class ObserverInfo: Disposable {
        fileprivate var action: ((_ result: ContentsType ) -> Void)
        fileprivate weak var observer: BwObserver?
        fileprivate var once: Bool = false
        fileprivate var main: Bool = true
        private var observable: BwObservable<ContentsType>?

        required public init(_ observer: BwObserver, observable: BwObservable<ContentsType>, once: Bool, main: Bool, action: @escaping ((ContentsType) -> Void)) {
            self.observer = observer
            self.once = once
            self.main = main
            self.action = action
            self.observable = observable
        }

        public func disposed( by disposeBag: BwDisposeBag) {
            disposeBag.set(self)
        }

        public func dispose() {
            if let _observer = observer {
                self.observable?.dispose(by: _observer)
            }
        }

        deinit {
            logger.debug("deinit")
        }
    }
    // **********************************************

    private var observerInfos: [ObserverInfo] = []
    private var latestContents: ContentsType?

    public init() {
        //observables.append(self)
    }

    /// subscribe
    ///
    /// - Parameters:
    ///   - observer: BwObserver that observe this BwObservable. This is just identifier of observer.
    ///   - once: subscribe once
    ///   - latest: immediately return contens, if it already exists.
    ///   - main: if true, action executed in main thread
    ///   - action: closure that is invoked when contents are published
    /// - Returns: ObserverInfo?
    @discardableResult
    public func subscribe(_ observer: BwObserver, latest: Bool = false, main: Bool = true, action: @escaping ((_ contents: ContentsType ) -> Void) ) -> ObserverInfo {
        if latest, let _latestContents = latestContents {
            DispatchQueue.main.async {
                action(_latestContents)
            }
        }

        let observerInfo = ObserverInfo(observer, observable: self, once: false, main: main, action: action)
        observerInfos.append(observerInfo)

        return observerInfo
    }

    public func once(_ observer: BwObserver, latest: Bool = false, main: Bool = true, action: @escaping ((_ contents: ContentsType ) -> Void) ) {
        if latest, let _latestContents = latestContents {
            DispatchQueue.main.async {
                action(_latestContents)
            }
            return
        }

        let observerInfo = ObserverInfo(observer, observable: self, once: true, main: main, action: action)
        observerInfos.append(observerInfo)
    }

    /// Execute action closures
    ///
    /// - Parameter contents: Contents to be published to subscribers(observers)
    public func publish(_ contents: ContentsType) {
        latestContents = contents
        for observerInfo in observerInfos {
            if observerInfo.main {
                DispatchQueue.main.async {
                    observerInfo.action(contents)
                }
            } else {
                observerInfo.action(contents)
            }
        }

        observerInfos = observerInfos.filter({ !$0.once })
    }

    /// Discard all ObserverInfo that own the observer specified in the instance
    ///
    /// - Parameter observer: observer
    public func dispose(by observer: BwObserver) {
        observerInfos = observerInfos.filter({ !($0.observer === observer) })
    }
}
