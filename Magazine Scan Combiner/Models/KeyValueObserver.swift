//
//  KeyValueObserver.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/6/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Foundation

class KeyValueObserver<ObservedObjectType: NSObject>: NSObject {
    private let object: ObservedObjectType
    private let keyPath: String
    private let observeBlock: (ObservedObjectType) -> ()
    private var context = 1

    init(object: ObservedObjectType, keyPath: String, options: NSKeyValueObservingOptions = .Initial, observeBlock: (ObservedObjectType) -> ()) {
        self.object = object
        self.keyPath = keyPath
        self.observeBlock = observeBlock

        super.init()

        object.addObserver(self, forKeyPath: keyPath, options: options, context: &context)
    }


    deinit {
        object.removeObserver(self, forKeyPath: keyPath, context: &context)
    }


    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        observeBlock(self.object)
    }
}