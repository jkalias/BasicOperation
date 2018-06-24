/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension to NSLock to simplify executing critical code.
*/

import Foundation

extension NSLock
{
    func critical<T>(_ block: () -> T) -> T
    {
        self.lock()
        let value = block()
        self.unlock()
        return value
    }
}
