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
public class BwDisposeBag
{
    private var disposables = [Disposable]()
    public init() {
    }
    fileprivate func set(_ deliverable: Disposable)
    {
        disposables.append(deliverable)
    }
    deinit {
        for disposable in disposables
        {
            disposable.dispose()
        }
    }
}

// =============================================================================
// MARK: - BwObservable
// =============================================================================

//var observables = [Any] ()

/// A protocol with a method for canceling subscribe all at once
fileprivate protocol Disposable
{
    func dispose()
}

/// A class that can be observed to return a specific results by closure
public class BwObservable<ContentsType>
{
    // **********************************************
    /// Class for returning observing results
    public class BwDeliverable: Disposable
    {
        fileprivate var action: ((_ result: ContentsType ) -> Void)
        fileprivate weak var observer: BwObserver?
        fileprivate var once: Bool = false
        private var observable: BwObservable<ContentsType>?
        
        required public init(_ observer: BwObserver, observable: BwObservable<ContentsType>, once: Bool, action: @escaping ((ContentsType) -> Void)) {
            self.observer = observer
            self.once = once
            self.action = action
            self.observable = observable
        }

        public func disposed( by disposeBag: BwDisposeBag)
        {
            disposeBag.set(self)
        }
        
        public func dispose()
        {
            if let _observer = self.observer
            {
                self.observable?.dispose(by: _observer)
            }
        }

        deinit
        {
            print("test comment: deinit")
        }
    }
    // **********************************************
    
    private var deliverables: [BwDeliverable] = []
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
    ///   - action: Closure that is invoked when contents are published
    /// - Returns: BwDeliverable?
    @discardableResult
    public func subscribe(_ observer: BwObserver, once: Bool = false, latest: Bool = false, action: @escaping ((_ contents: ContentsType ) -> Void) ) -> BwDeliverable?
    {
        if latest, let _latestContents = latestContents
        {
            DispatchQueue.main.async {
                action(_latestContents)
            }
            if once { return nil }
        }

        let deliverable = BwDeliverable(observer, observable: self, once: once, action: action)
        deliverables.append(deliverable)
    
        return deliverable
    }

    /// Execute action closures
    ///
    /// - Parameter contents: Contents to be published to subscribers(observers)
    public func publish(_ contents: ContentsType)
    {
        latestContents = contents
        for deliverable in deliverables
        {
            deliverable.action(contents)
        }
        
        deliverables = deliverables.filter({!$0.once})
    }

    /// Discard all BwDeliverable that own the observer specified in the instance
    ///
    /// - Parameter observer: observer
    public func dispose(by observer: BwObserver)
    {
        deliverables = deliverables.filter({ !($0.observer === observer) })
    }
}
