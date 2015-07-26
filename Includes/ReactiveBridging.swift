//
//  ReactiveBridging.swift
//  S10
//
//  Created by Tony Xiao on 7/13/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import ReactiveCocoa
import BrightFutures
import Bond
import Box

// MARK: - ReactiveCocoa + SwiftBonds

private class RetainingDynamicArray<T>: DynamicArray<T> {
    override init(_ v: Array<T>) {
        super.init(v)
    }
    var retainedObjects: [AnyObject] = []
    func retain(object: AnyObject) {
        retainedObjects.append(object)
    }
}

func toBondDynamicArray<T, P: PropertyType where P.Value == [T]>(property: P) -> DynamicArray<T> {
    let dyn = RetainingDynamicArray<T>(property.value)
    dyn.retain(Box(property))
    property.producer.start(next: { [weak dyn] value in
        dyn?.value = value
    })
    return dyn
}

func toBondDynamic<T, P: PropertyType where P.Value == T>(property: P) -> Dynamic<T> {
    let dyn = InternalDynamic<T>(property.value)
    dyn.retain(Box(property))
    property.producer.start(next: { [weak dyn] value in
        dyn?.value = value
    })
    return dyn
}

/// Output Dynamic retains input property
func toBondDynamic<T, P: MutablePropertyType where P.Value == T>(property: P) -> Dynamic<T> {
    var updatingFromSelf = false
    let reverseBond = Bond<T>() { [weak property] v in
        if !updatingFromSelf {
            property?.value = v
        }
    }
    let dyn = InternalDynamic<T>(property.value)
    dyn.retain(Box(property))
    dyn.retain(reverseBond)
    property.producer.start(next: { [weak dyn] value in
        updatingFromSelf = true
        dyn?.value = value
        updatingFromSelf = false
    })
    reverseBond.bind(dyn, fire: false, strongly: false)
    return dyn
}

/// Output PropertyOf which retains source dynamic
func fromBondDynamic<T, D: Dynamical where D.DynamicType == T>(d: D) -> PropertyOf<T> {
    return fromBondDynamic(d.designatedDynamic)
}

/// Output PropertyOf which retains source dynamic
func fromBondDynamic<T>(dynamic: Dynamic<T>) -> PropertyOf<T> {
    let (signal, sink) = Signal<T, ReactiveCocoa.NoError>.pipe()
    let bond = Bond<T>() { value in
        sendNext(sink, value)
    }
    bond.bind(dynamic, fire: false, strongly: true)
    return PropertyOf(dynamic.value) {
        return signal |> map { v in
            let retainedBond = bond // Force retain bond
            return v
        }
    }
}

// MARK: Bindings

extension UITextField : Bondable, Dynamical {
}
extension UITextView : Dynamical {
}

// Two way bind

func <->> <T, P: MutablePropertyType where P.Value == T>(left: P, right: Dynamic<T>) {
    toBondDynamic(left) <->> right
}

func <->> <D: Dynamical, P: MutablePropertyType where D.DynamicType == P.Value>(left: P, right: D) {
    toBondDynamic(left) <->> right.designatedDynamic
}

// Bind and fire

func ->> <P: PropertyType, T where P.Value == T>(left: P, right: Bond<T>) {
    toBondDynamic(left) ->> right
}

func ->> <T: PropertyType, U: Bondable where T.Value == U.BondType>(left: T, right: U) {
    toBondDynamic(left) ->> right.designatedBond
}

// Bind only

func ->| <P: PropertyType, T where P.Value == T>(left: P, right: Bond<T>) {
    toBondDynamic(left) ->| right
}

func ->| <T: PropertyType, U: Bondable where T.Value == U.BondType>(left: T, right: U) {
    toBondDynamic(left) ->| right.designatedBond
}

// MARK: - ReactiveCocoa + BrightFutures

let errSignalInterrupted = NSError(domain: "ReactiveCocoa", code: NSUserCancelledError, userInfo: nil)

extension SignalProducer {
    func future() -> Future<T, NSError> {
        let promise = Promise<T, NSError>()
        var value: T?
        start(error: {
            promise.failure($0.nsError)
            }, interrupted: {
                promise.failure(errSignalInterrupted)
            }, completed: {
                if let value = value {
                    promise.success(value)
                } else {
                    promise.success(() as! T)
                }
            }, next: {
                assert(value == nil, "future should only have 1 value")
                value = $0
        })
        return promise.future
    }
}

extension Future {
    func signalProducer() -> SignalProducer<T, NSError> {
        // TODO: Make more sense of memory management
        return SignalProducer { sink, disposable in
            // Local variable to work around swiftc compilation bug
            // http://www.markcornelisse.nl/swift/swift-invalid-linkage-type-for-function-declaration/
            let successBlock: T -> () = {
                sendNext(sink, $0)
                sendCompleted(sink)
            }
            self.onSuccess(callback: successBlock).onFailure {
                sendError(sink, $0.nsError)
            }
        }
    }
}

// MARK: - ReactiveCocoa 2.x

// Avoid having to type cast all the time
extension RACSignal {
    func subscribeNextAs<T>(nextClosure:(T) -> ()) -> RACDisposable {
        return self.subscribeNext { (next: AnyObject!) -> () in
            let nextAsT = next as! T
            nextClosure(nextAsT)
        }
    }
    
    func subscribeErrorOrCompleted(block: (NSError?) -> ()) {
        subscribeError({ error in
            block(error)
            }, completed:{
                block(nil)
        })
    }
    
    // replayWithSubject has the advantage that signal would be subscribed to but
    // disposed as soon as subject is deallocated, rather than replay() in which signal is never
    // disposed of even if no one is listening to the subject anymore
    public func replayWithSubject() -> RACSignal {
        let subject = RACReplaySubject()
        subscribe(subject)
        return subject
    }
}

extension RACSubject {
    func sendNextAndCompleted(value: AnyObject!) {
        sendNext(value)
        sendCompleted()
    }
}

extension NSObject {
    // TODO: Convert these to RAC 3 with swift
    func listenForNotification(name: String) -> RACSignal/*<NSNotification>*/ {
        return listenForNotification(name, object: nil)
    }
    
    func listenForNotification(name: String, object: AnyObject?) -> RACSignal/*<NSNotification>*/ {
        let nc = NSNotificationCenter.defaultCenter()
        return nc.rac_addObserverForName(name, object: object).takeUntil(rac_willDeallocSignal())
    }
    
    func listenForNotification(name: String, selector: Selector, object: AnyObject? = nil) {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: selector, name: name, object: object)
        rac_willDeallocSignal().subscribeCompleted { [weak self] in
            nc.removeObserver(self!)
        }
    }
    
    func racObserve(keyPath: String) -> RACSignal {
        return self.rac_valuesForKeyPath(keyPath, observer: self)
    }
}
