//
//  ReactiveFuture.swift
//  S10
//
//  Created by Tony Xiao on 7/14/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result

public struct Promise<T, E: ErrorType> {

    private let sink: SinkOf<Event<T, E>>
    public let future: Future<T, E>
    
    public init(_ block: ((Promise<T, E>) -> ())? = nil) {
        let (buffer, sink) = SignalProducer<T, E>.buffer(1)
        self.sink = sink
        future = Future(buffer: buffer)
        block?(self)
    }
    
    public func complete(result: Result<T, E>?) {
        assert(future.result == nil, "Promise should not be fulfulled multiple times")
        if let result = result {
            result.analysis(ifSuccess: {
                sendNext(sink, $0)
                sendCompleted(sink)
            }, ifFailure: {
                sendError(sink, $0)
            })
        } else {
            sendInterrupted(sink)
        }
    }
    
    public func cancel() {
        complete(nil)
    }
    
    public func success(value: T) {
        complete(Result(value: value))
    }
    
    public func failure(error: E) {
        complete(Result(error: error))
    }
    
    public static func create<T, E: ErrorType>(@noescape block: (Promise<T, E> -> ())) -> Future<T, E> {
        let promise = Promise<T, E>()
        block(promise)
        return promise.future
    }
}

public struct Future<T, E: ErrorType> {
    private let buffer: SignalProducer<T, E>
    private let _result: () -> Result<T, E>?
    public var result: Result<T, E>? { return _result() }
    public var value: T? { return result?.value }
    public var error: E? { return result?.error }
    public var producer: SignalProducer<T, E> { return buffer }
    
    private init(buffer: SignalProducer<T, E>) {
        self.buffer = buffer
        var r: Result<T, E>?
        _result = { r }
        onComplete { r = $0 }
    }
    
    public static var cancelled: Future {
        return self(buffer: SignalProducer { observer, disposable in
            sendInterrupted(observer)
        })
    }
    
    public init(error: E) {
        self.init(buffer: SignalProducer(error: error))
    }
    
    public init(value: T) {
        self.init(buffer: SignalProducer(value: value))
    }
    
    public init(workToStart: SignalProducer<T, E>) {
        let (buffer, sink) = SignalProducer<T, E>.buffer(1)
        (workToStart |> take(1)).start(sink)
        self.init(buffer: buffer)
    }
    
    public init(startedWork: Signal<T, E>) {
        let (buffer, sink) = SignalProducer<T, E>.buffer(1)
        (startedWork |> take(1)).observe(sink)
        self.init(buffer: buffer)
    }
    
    public func observe(callback: Result<T, E>? ->()) -> Disposable {
        var result: Result<T, E>?
        let sink = Event<T, E>.sink(next: { v in
            result = Result(value: v)
        }, completed: {
            callback(result!)
        }, error: { e in
            result = Result(error: e)
            callback(result!)
        }, interrupted: {
            callback(nil)
        })
        var disposable: Disposable!
        buffer.startWithSignal { signal, innerDisposable in
            signal.observe(sink)
            disposable = innerDisposable
        }
        return disposable
    }
    
    public func observe(success: (T -> ())? = nil, failure: (E -> ())? = nil, cancel: (() -> ())? = nil, complete: (Result<T, E> -> ())? = nil) -> Disposable {
        return observe { result in
            if let result = result {
                result.analysis(ifSuccess: { success?($0) }, ifFailure: { failure?($0) })
                complete?(result)
            } else {
                cancel?()
            }
        }
    }
    
    public func onComplete(callback: Result<T, E> ->()) -> Future<T, E> {
        observe(complete: callback)
        return self
    }
    
    public func onCancel(callback: () -> ()) -> Future<T, E> {
        observe(cancel: callback)
        return self
    }
    
    public func onSuccess(callback: T -> ()) -> Future<T, E> {
        observe(success: callback)
        return self
    }
    
    public func onFailure(callback: E -> ()) -> Future<T, E> {
        observe(failure: callback)
        return self
    }
    
    public func onTerminate(callback: Result<T, E>? -> ()) -> Future<T, E> {
        observe(callback)
        return self
    }
    
    // Unary lift
    
    public func lift<U, F>(transform: Signal<T, E> -> Signal<U, F>) -> Future<U, F> {
        return Future<U, F>(buffer: buffer.lift(transform))
    }
    
    public func lift<U, F>(transform: SignalProducer<T, E> -> SignalProducer<U, F>) -> Future<U, F> {
        return Future<U, F>(buffer: transform(buffer))
    }
    
    // Binary lift
    
    public func lift<U, F, V, G>(transform: Signal<U, F> -> (Signal<T, E> -> Signal<V, G>)) -> Future<U, F> -> Future<V, G> {
        return { otherFuture in
            return Future<V, G>(buffer: self.buffer.lift(transform)(otherFuture.buffer))
        }
    }
    
    public func lift<U, F, V, G>(transform: SignalProducer<U, F> -> (SignalProducer<T, E> -> SignalProducer<V, G>)) -> Future<U, F> -> Future<V, G> {
        return { otherFuture in
            return Future<V, G>(buffer: transform(otherFuture.buffer)(self.buffer))
        }
    }
    
}

// Pipe operator support and free fuctions

public func |> <T, E, X>(future: Future<T, E>, @noescape transform: Future<T, E> -> X) -> X {
    return transform(future)
}

public func deliverOn<T, E>(scheduler: SchedulerType) -> Future<T, E> -> Future<T, E> {
    return { future in
        return Future(buffer: future.buffer |> observeOn(scheduler))
    }
}

public func onSuccess<T, E>(block: T -> ()) -> Future<T, E> -> Future<T, E> {
    return { future in
        return future.onSuccess(block)
    }
}

public func onFailure<T, E>(block: E -> ()) -> Future<T, E> -> Future<T, E> {
    return { future in
        return future.onFailure(block)
    }
}

public func onComplete<T, E>(block: Result<T, E> -> ()) -> Future<T, E> -> Future<T, E> {
    return { future in
        return future.onComplete(block)
    }
}

public func onCancel<T, E>(block: () -> ()) -> Future<T, E> -> Future<T, E> {
    return { future in
        return future.onCancel(block)
    }
}

public func onTerminate<T, E>(block: Result<T, E>? -> ()) -> Future<T, E> -> Future<T, E> {
    return { future in
        return future.onTerminate(block)
    }
}


public func flatMap<T, U, E>(transform: T -> Future<U, E>) -> Future<T, E> -> Future<U, E> {
    return { future in
        // Specific strategy here doesn't matter because there will only ever be at most value to be
        // transformed
        return future |> flatMap(.Latest) { transform($0).buffer }
    }
}

// Unary Lift

public func |> <T, E, U, F>(future: Future<T, E>, transform: Signal<T, E> -> Signal<U, F>) -> Future<U, F> {
    return future.lift(transform)
}

public func |> <T, E, U, F>(future: Future<T, E>, transform: SignalProducer<T, E> -> SignalProducer<U, F>) -> Future<U, F> {
    return future.lift(transform)
}

// Convert from signal producer & signal

public func toFuture<T, E: ErrorType>(producer: SignalProducer<T, E>) -> Future<T, E> {
    return Future(workToStart: producer)
}

public func toFuture<T, E: ErrorType>(signal: Signal<T, E>) -> Future<T, E> {
    return Future(startedWork: signal)
}
