//
//  URL+Pasteboard.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/20/2016.
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

import Cocoa


/// This extension simply adds `NSURL`’s from-pasteboard initializer to URL so that it can be
/// used without casting.
extension URL {
    /// Reads a URL object from the specified pasteboard.
    /// - parameter pasteboard: The target pasteboard.
    /// - returns: a URL object, or `nil` if the pasteboard does not contain `NSURLPboardType` data.
    init?(from pasteboard: NSPasteboard) {
        guard let url = (NSURL(from: pasteboard) as URL?) else {
            return nil
        }

        self = url
    }
}
