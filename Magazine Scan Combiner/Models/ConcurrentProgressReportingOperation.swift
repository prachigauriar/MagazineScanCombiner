//
//  ConcurrentProgressReportingOperation.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/6/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Foundation

class ConcurrentProgressReportingOperation: NSOperation, NSProgressReporting {
    // MARK: - Concurrent NSOperation subclass overrides

    override var asynchronous: Bool {
        return true
    }


    private var _executing: Bool = false
    override var executing: Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }


    private var _finished: Bool = false
    override var finished: Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }


    // MARK: - NSProgressReporting

    let progress: NSProgress = NSProgress(parent: nil, userInfo: nil)
}