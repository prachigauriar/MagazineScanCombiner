//
//  URL+Pasteboard.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/20/2016.
//  Copyright © 2016 Prachi Gauriar. All rights reserved.
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
