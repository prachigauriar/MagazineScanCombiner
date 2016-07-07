//
//  KeyValueObserver.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/6/2016.
//  Copyright © 2016 Prachi Gauriar.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
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