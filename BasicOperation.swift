//
//  BasicOperation.swift
//

import Foundation

private let KeyPathSetForAffectingValuesKVO : Set<String> = ["state"]

/*
  -> "@objc" is needed in order to expose the property to the ObjC runtime (KVO is based on it)
  -> "dynamic" is needed in order to force the compiler to use dynamic dispatch through the ObjC runtime (no static Swift dispatch)
 */

class BasicOperation: Operation
{
    // this is needed for manual KVO
    @objc dynamic override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        return false
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingReady() -> Set<String> {
        return KeyPathSetForAffectingValuesKVO
    }

    @objc private dynamic class func keyPathsForValuesAffectingExecuting() -> Set<String> {
        return KeyPathSetForAffectingValuesKVO
    }

    @objc private dynamic class func keyPathsForValuesAffectingFinished() -> Set<String> {
        return KeyPathSetForAffectingValuesKVO
    }

    @objc private dynamic class func keyPathsForValuesAffectingCancelled() -> Set<String> {
        return KeyPathSetForAffectingValuesKVO
    }
    
    @objc dynamic override var isReady: Bool {
        for dep in dependencies {
            if dep.isCancelled {
                return false
            }
            if dep.isFinished {
                return true
            }
        }
        return state == .ready
    }
    @objc dynamic override var isExecuting: Bool    { return state == .executing }
    @objc dynamic override var isFinished: Bool     { return state == .finished || isCancelled }
    @objc dynamic override var isCancelled: Bool    { return state == .cancelled }
    @objc dynamic override var isAsynchronous: Bool {return true}
    
    var completionBlockWhenCancelled: (() -> ())? = nil
    
    private var _state = State.ready
    private let stateLock = NSLock()
    
    @objc dynamic var state : State {
        get {
            return stateLock.critical {
                _state
            }
        }
        set(newState) {
            willChangeValue(forKey: "state")
            stateLock.critical { () -> () in
                _state = newState
            }
            didChangeValue(forKey: "state")
        }
    }
    
    // must be @objc so the ObjC runtime can "see" it
    @objc enum State: Int {
        case ready
        case executing
        case finished
        case cancelled
    }
    
    override func start() {
        if !isCancelled {
            state = .executing
            main()
        }
    }
    
    override func main() {
        if !isCancelled {
            execute()
        }
    }
    
    func execute() {
        fatalError("must be overwritten from subclasses")
    }
    
    func finish() {
        state = .finished
    }
    
    override func cancel() {
        state = .cancelled
        super.cancel()
        if let block = completionBlockWhenCancelled {
            block()
        }
    }
}
